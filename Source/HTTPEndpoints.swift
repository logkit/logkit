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


/// A default selection of HTTP status codes that will be interpreted as a successful upload.
private let defaultSuccessCodes = Set([200, 201, 202, 204])


/**
This utility class holds data until the endpoint is ready to upload it. The data is also persisted to a file, in case the
upload does not succeed while the application is running. We always read the file on startup to see if there are any left-over
uploads to complete.
*/
private class LXPersistedCache {
    private let lock: dispatch_queue_t = dispatch_queue_create("persistedCacheQueue", DISPATCH_QUEUE_SERIAL)
    private let file: NSFileHandle?
    private var cache: [UInt: NSData]
    private var reserved: [UInt: NSTimeInterval] = [:]
    private let timeoutInterval: NSTimeInterval
    private var currentMaxID: UInt

    /**
    Initialize a persistent cache instance.
    
    - parameter timeoutInterval: The amount of time data will remain reserved before assuming the upload failed, and allowing
    the data to be tried again.
    - parameter fileName: The cache file's name. This file will be created in the directory indicated by
    `LK_DEFAULT_LOG_DIRECTORY`.
    */
    init(timeoutInterval: NSTimeInterval, fileName: String) {
        self.timeoutInterval = timeoutInterval
        if let fileURL = LK_DEFAULT_LOG_DIRECTORY?.URLByAppendingPathComponent(fileName, isDirectory: false) {
            NSFileManager.defaultManager().ensureFileAtURL(fileURL, withIntermediateDirectories: true)
            do { try self.file = NSFileHandle(forUpdatingURL: fileURL) } catch { self.file = nil }
        } else {
            self.file = nil
        }
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

    /// Clean up
    deinit {
        dispatch_barrier_sync(self.lock, {
            self.file?.synchronizeFile()
            self.file?.closeFile()
        })
    }

    /// Add data to the cache; the data can be retrieved for upload later.
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

    /**
    Reserve data for upload. Once data has been reserved, it will not be reserved again until its reservation ends.
    
    Users should track each ID number associated with the data they reserve. Once an upload succeeds, the user should call
    `completeProgressOnIDs(:)` with each of the ID numbers of the data that successfully uploaded, so that the cache can discard
    that data. If an upload fails, user should call `cancelProgressOnIDs(:)` with the relevant IDs, so that the cache can allow
    that data to be reserved again.
    
    If the cache does not recieve either signal by the end of the reservation interval, it will automatically make the data
    available for reservation again.
    
    - returns: A dictionary of ID numbers and data.
    */
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

    /// Call this method when data has been successfully uploaded. The cache will discard this data.
    func completeProgressOnIDs(ids: [UInt]) {
        dispatch_async(self.lock, {
            for id in ids {
                self.cache.removeValueForKey(id)
                self.reserved.removeValueForKey(id)
            }

            self.file?.truncateFileAtOffset(0)
            if self.cache.isEmpty {
                self.currentMaxID = 0
            } else {
                let output = self.cache.map({ id, data in self.dataString(data, withID: id) }).joinWithSeparator("")
                if let fileData = output.dataUsingEncoding(NSUTF8StringEncoding) {
                    self.file?.writeData(fileData)
                } else {
                    //TODO: what do we really want to do if encoding fails?
                    assertionFailure("Failure to encode data for temporary storage")
                }
            }
        })
    }

    /**
    Call this method when data has failed to upload. The cache will end the data's reservation and allow a subsequent attempt
    to upload the data again.
    */
    func cancelProgressOnIDs(ids: [UInt]) {
        dispatch_async(self.lock, {
            for id in ids {
                self.reserved.removeValueForKey(id)
            }
        })
    }

    /// Formats the data for persistent storage.
    private func dataString(data: NSData, withID id: UInt) -> String {
        return "\(id) \(data.base64EncodedStringWithOptions([]))\n"
    }

}


/**
An endpoint that uploads log entries to an HTTP service in JSON format. Attempts to upload entries in order, but
makes no guarantee.
*/
public class LXHTTPEndpoint: LXEndpoint {
    public var minimumPriorityLevel: LXPriorityLevel
    public var dateFormatter: LXDateFormatter
    public var entryFormatter: LXEntryFormatter
    public let requiresNewlines: Bool = false

    private let successCodes: Set<Int>
    private let session: NSURLSession
    private let request: NSURLRequest

    private var cacheName: String { return ".http_endpoint_cache.txt" }
    private lazy var cache: LXPersistedCache = LXPersistedCache(timeoutInterval: 50, fileName: self.cacheName)
    private lazy var timer: NSTimer = {
        let timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: "upload:", userInfo: nil, repeats: true)
        timer.tolerance = 10
        return timer
    }()

    /**
    Initialize an HTTP endpoint.

    - parameters:
      - request: The URL request that will used when submitting all uploads.
      - successCodes: (optional) A set of HTTP status codes which will be considered indicative of a successful upload. Defaults
      to `{200, 201, 202, 204}`.
      - sessionConfiguration: (optional) The configuration to be used when initializating this endpoint's URL session. Defaults to
      `NSURLSessionConfiguration.defaultSessionConfiguration()`.
      - minimumPriorityLevel: (optional) Only log entries of this level or above will be written to this endpoint. Defaults to
      `All`.
      - dateFormatter: (optional) The date formatter that this endpoint will use to convert an entry's `dateTime` to a string.
      Defaults to `LXDateFormatter.standardFormatter()`.
      - entryFormatter: (optional) The entry formatter that this endpoint will use to convert an entry instnace to a string.
      Defaults to `LXEntryFormatter.standardFormatter()`.
    */
    public init(
        request: NSURLRequest,
        successCodes: Set<Int> = defaultSuccessCodes,
        sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(),
        minimumPriorityLevel: LXPriorityLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        self.minimumPriorityLevel = minimumPriorityLevel
        self.dateFormatter = dateFormatter
        self.entryFormatter = entryFormatter

        self.successCodes = successCodes
        self.session = NSURLSession(configuration: sessionConfiguration)
        self.request = request

        self.timer.fire()
    }

    /**
    Initialize an HTTP endpoint.

    - parameters:
      - URL: The URL to upload the log entry to.
      - HTTPMethod: The HTTP request method to be used when uploading log entries.
      - successCodes: (optional) A set of HTTP status codes which will be considered indicative of a successful upload. Defaults
      to `{200, 201, 202, 204}`.
      - sessionConfiguration: (optional) The configuration to be used when initializating this endpoint's URL session. Defaults to
      `NSURLSessionConfiguration.defaultSessionConfiguration()`.
      - minimumPriorityLevel: (optional) Only log entries of this level or above will be written to this endpoint. Defaults to
      `All`.
      - dateFormatter: (optional) The date formatter that this endpoint will use to convert an entry's `dateTime` to a string.
      Defaults to `LXDateFormatter.standardFormatter()`.
      - entryFormatter: (optional) The entry formatter that this endpoint will use to convert an entry instnace to a string.
      Defaults to `LXEntryFormatter.standardFormatter()`.
    */
    public convenience init(
        URL: NSURL,
        HTTPMethod: String,
        successCodes: Set<Int> = defaultSuccessCodes,
        sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(),
        minimumPriorityLevel: LXPriorityLevel = .All,
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
            minimumPriorityLevel: minimumPriorityLevel,
            dateFormatter: dateFormatter,
            entryFormatter: entryFormatter
        )
    }

    /// Clean up
    deinit {
        self.timer.fire()
        self.timer.invalidate()
        self.session.finishTasksAndInvalidate()
    }

    /// Submits data for uploading.
    public func write(string: String) {
        guard let data = string.dataUsingEncoding(NSUTF8StringEncoding) else {
            assertionFailure("Failure to create data from entry string")
            return
        }
        self.cache.addData(data)
        self.timer.fire() // or should we just wait for the next timer firing?
    }

    /// Attempts to upload all available pending data.
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


/**
An endpoint that uploads log entries to an HTTP service in JSON format. Attempts to upload entries in order, but
makes no guarantee.
*/
public class LXHTTPJSONEndpoint: LXHTTPEndpoint {

    private override var cacheName: String { return ".json_endpoint_cache.txt" }

    /**
    Initialize an HTTP JSON endpoint. Log entries will be converted to JSON automatically.

    - parameters:
      - request: The URL request that will used when submitting all uploads.
      - successCodes: (optional) A set of HTTP status codes which will be considered indicative of a successful upload. Defaults
      to `{200, 201, 202, 204}`.
      - sessionConfiguration: (optional) The configuration to be used when initializating this endpoint's URL session. Defaults to
      `NSURLSessionConfiguration.defaultSessionConfiguration()`.
      - minimumPriorityLevel: (optional) Only log entries of this level or above will be written to this endpoint. Defaults to
      `All`.
      - dateFormatter: (optional) The date formatter that this endpoint will use to convert an entry's `dateTime` to a string.
      Defaults to `LXDateFormatter.standardFormatter()`.
    */
    public init(
        request: NSURLRequest,
        successCodes: Set<Int> = defaultSuccessCodes,
        sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(),
        minimumPriorityLevel: LXPriorityLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.ISO8601DateTimeFormatter()
    ) {
        super.init(
            request: request,
            successCodes: successCodes,
            sessionConfiguration: sessionConfiguration,
            minimumPriorityLevel: minimumPriorityLevel,
            dateFormatter: dateFormatter,
            entryFormatter: LXEntryFormatter.jsonFormatter()
        )
    }

    /**
    Initialize an HTTP JSON endpoint. Log entries will be converted to JSON automatically.

    - parameters:
      - URL: The URL to upload the log entry to.
      - HTTPMethod: The HTTP request method to be used when uploading log entries.
      - successCodes: (optional) A set of HTTP status codes which will be considered indicative of a successful upload. Defaults
      to `{200, 201, 202, 204}`.
      - sessionConfiguration: (optional) The configuration to be used when initializating this endpoint's URL session. Defaults to
      `NSURLSessionConfiguration.defaultSessionConfiguration()`.
      - minimumPriorityLevel: (optional) Only log entries of this level or above will be written to this endpoint. Defaults to
      `All`.
      - dateFormatter: (optional) The date formatter that this endpoint will use to convert an entry's `dateTime` to a string.
      Defaults to `LXDateFormatter.standardFormatter()`.
    */
    public convenience init(
        URL: NSURL,
        HTTPMethod: String,
        successCodes: Set<Int> = defaultSuccessCodes,
        sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(),
        minimumPriorityLevel: LXPriorityLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.ISO8601DateTimeFormatter()
    ) {
        let request = NSMutableURLRequest(URL: URL)
        request.HTTPMethod = HTTPMethod
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        self.init(
            request: request,
            successCodes: successCodes,
            sessionConfiguration: sessionConfiguration,
            minimumPriorityLevel: minimumPriorityLevel,
            dateFormatter: dateFormatter
        )
    }

}
