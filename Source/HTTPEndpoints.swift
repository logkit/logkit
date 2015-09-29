// HTTPEndpoints.swift
//
// Copyright (c) 2015, Justin Pawela & The LogKit Project (http://www.logkit.info/)
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

import Foundation


private let defaultSuccessCodes = Set([200, 201, 202, 204])
private let defaultCacheFileURL: NSURL = {
    guard let URL = LK_DEFAULT_LOG_DIRECTORY?.URLByAppendingPathComponent("httpCache.txt", isDirectory: false) else {
        assertionFailure("Failure to resolve default HTTP Endpoint cache file URL")
        return NSURL(string: "")!
    }
    return URL
}()


private class LXPersistedCache {
    private let lock: dispatch_queue_t = dispatch_queue_create("persistedCacheQueue", DISPATCH_QUEUE_SERIAL)
    private let file: NSFileHandle?
    private var cache: [UInt: NSData]
    private var reserved: [UInt: NSTimeInterval] = [:]
    private let timeoutInterval: NSTimeInterval
    private var currentMaxID: UInt

    init(timeoutInterval: NSTimeInterval) {
        self.timeoutInterval = timeoutInterval
        NSFileManager.defaultManager().ensureFileAtURL(defaultCacheFileURL, withIntermediateDirectories: true)
        do { try self.file = NSFileHandle(forUpdatingURL: defaultCacheFileURL) } catch { self.file = nil }
        self.file?.seekToFileOffset(0) // Do we need to do this?
        self.cache = [:]
        let encoded = self.file?.readDataToEndOfFile() ?? NSData()
        if let decoded = NSString(data: encoded, encoding: NSUTF8StringEncoding) as? String {
            for lines in decoded.componentsSeparatedByString("\n") {
                let line = lines.componentsSeparatedByString(" ")
                if line.count == 2, let id = UInt(line[0]), data = NSData(base64EncodedString: line[1], options: []) {
                    self.cache[id] = data
                } //TODO: error handling - corrupted file?
            }
        }
        self.currentMaxID = self.cache.keys.maxElement() ?? 0
        assert(self.file != nil, "HTTP Cache could not open cache file.")
    }

    deinit {
        dispatch_barrier_sync(self.lock, {
            self.file?.synchronizeFile()
            self.file?.closeFile()
        })
    }

    func addData(data: NSData) {
        dispatch_async(self.lock, {
            let id = ++self.currentMaxID
            self.cache[id] = data

            self.file?.seekToEndOfFile() // Do we need to do this?
            guard let outData = self.dataString(data, withID: id).dataUsingEncoding(NSUTF8StringEncoding) else {
                assertionFailure("Failure to encode data for temporary storage")
                return
            }
            self.file?.writeData(outData)
        })
    }

    func reserveData() -> [UInt: NSData] {
        var toReserve: [UInt: NSData]?
        dispatch_sync(self.lock, {
            let now = CFAbsoluteTimeGetCurrent()
            toReserve = self.cache
            let ignored = self.reserved.filter({ _, expiry in now < expiry }).map({ id, _ in id })
            for id in ignored { toReserve!.removeValueForKey(id) }
            let expires = now + self.timeoutInterval
            for id in toReserve!.keys { self.reserved[id] = expires }
        })
        return toReserve!
    }

    func completeProgressOnIDs(ids: [UInt]) {
        dispatch_async(self.lock, {
            for id in ids {
                self.cache.removeValueForKey(id)
                self.reserved.removeValueForKey(id)
            }

            var completeOutput: String = ""
            for (id, data) in self.cache {
                completeOutput += self.dataString(data, withID: id)
            }
            guard let fileData = completeOutput.dataUsingEncoding(NSUTF8StringEncoding) else {
                assertionFailure("Failure to encode data for temporary storage")
                return //TODO: what do we really want to do if encoding fails? leave the file alone? dump what was in there?
            }
            self.file?.truncateFileAtOffset(0)
            self.file?.writeData(fileData)
        })
    }

    func cancelProgressOnIDs(ids: [UInt]) {
        dispatch_async(self.lock, {
            for id in ids {
                self.reserved.removeValueForKey(id)
            }
        })
    }

    func dataString(data: NSData, withID id: UInt) -> String {
        return "\(id) \(data.base64EncodedStringWithOptions([]))\n"
    }

}

/// Makes an attempt to upload entries in order, but no guarantee
public class LXHTTPEndpoint: LXEndpoint {
    public var minimumLogLevel: LXPriorityLevel
    public var dateFormatter: LXDateFormatter
    public var entryFormatter: LXEntryFormatter
    public let requiresNewlines: Bool = false

    private let successCodes: Set<Int>
    private let session: NSURLSession
    private let request: NSURLRequest

    private let cache: LXPersistedCache = LXPersistedCache(timeoutInterval: 50)
    private lazy var timer: NSTimer = {
        let timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: "upload:", userInfo: nil, repeats: true)
        timer.tolerance = 10
        return timer
    }()

    public init(
        request: NSURLRequest,
        successCodes: Set<Int> = defaultSuccessCodes,
        sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(),
        minimumLogLevel: LXPriorityLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        self.minimumLogLevel = minimumLogLevel
        self.dateFormatter = dateFormatter
        self.entryFormatter = entryFormatter

        self.successCodes = successCodes
        self.session = NSURLSession(configuration: sessionConfiguration)
        self.request = request

        self.timer.fire()
    }

    public convenience init(
        URL: NSURL,
        HTTPMethod: String,
        successCodes: Set<Int> = defaultSuccessCodes,
        sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(),
        minimumLogLevel: LXPriorityLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        let request = NSMutableURLRequest(URL: URL)
        request.HTTPMethod = HTTPMethod
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        self.init(
            request: request,
            successCodes: successCodes,
            sessionConfiguration: sessionConfiguration,
            minimumLogLevel: minimumLogLevel,
            dateFormatter: dateFormatter,
            entryFormatter: entryFormatter
        )
    }

    deinit {
        self.timer.fire()
        self.timer.invalidate()
        self.session.finishTasksAndInvalidate()
    }

    public func write(string: String) {
        guard let data = string.dataUsingEncoding(NSUTF8StringEncoding) else {
            assertionFailure("Failure to create data from entry string")
            return
        }
        self.cache.addData(data)
        self.timer.fire() // or should we just wait for the next timer firing?
    }

    @objc private func upload(timer: NSTimer?) {
        dispatch_async(LK_LOGKIT_QUEUE, {
            let pendingUploads = self.cache.reserveData()
            for (id, data) in pendingUploads {
                let task = self.session.uploadTaskWithRequest(self.request, fromData: data, completionHandler: { _, response, _ in
                    if self.successCodes.contains((response as? NSHTTPURLResponse)?.statusCode ?? -1) {
                        self.cache.completeProgressOnIDs([id]) //TODO: more efficient releasing
                    } else {
                        self.cache.cancelProgressOnIDs([id])
                    }
                })
                task.resume()
            }
        })
    }

}


public class LXHTTPJSONEndpoint: LXHTTPEndpoint {

    public init(
        request: NSURLRequest,
        successCodes: Set<Int> = defaultSuccessCodes,
        sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(),
        minimumLogLevel: LXPriorityLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter()
    ) {
        super.init(
            request: request,
            successCodes: successCodes,
            sessionConfiguration: sessionConfiguration,
            minimumLogLevel: minimumLogLevel,
            dateFormatter: dateFormatter,
            entryFormatter: LXEntryFormatter.jsonFormatter()
        )
    }

    public convenience init(
        URL: NSURL,
        HTTPMethod: String,
        successCodes: Set<Int> = defaultSuccessCodes,
        sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(),
        minimumLogLevel: LXPriorityLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter()
    ) {
        let request = NSMutableURLRequest(URL: URL)
        request.HTTPMethod = HTTPMethod
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        self.init(
            request: request,
            successCodes: successCodes,
            sessionConfiguration: sessionConfiguration,
            minimumLogLevel: minimumLogLevel,
            dateFormatter: dateFormatter
        )
    }

}
