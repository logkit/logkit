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


/// Makes an attempt to upload entries in order, but no guarantee
public class LXHTTPEndpoint: LXEndpoint {
    public var minimumLogLevel: LXLogLevel
    public var dateFormatter: LXDateFormatter
    public var entryFormatter: LXEntryFormatter
    public let requiresNewlines: Bool = false

    private let lock: dispatch_queue_t = dispatch_queue_create("LX-HTTPEndpoint-Family-Lock", DISPATCH_QUEUE_SERIAL)
    private var suspended: Bool = false
    private var pending: [NSURLSessionTask] = []
    private lazy var clearTimer: dispatch_source_t = { return self.newClearTimer() }()

    private let successCodes: Set<Int>
    private let session: NSURLSession
    private let request: NSURLRequest

    public init(
        request: NSURLRequest,
        successCodes: Set<Int> = Set([200, 201, 202, 204]),
        sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(),
        minimumLogLevel: LXLogLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        self.minimumLogLevel = minimumLogLevel
        self.dateFormatter = dateFormatter
        self.entryFormatter = entryFormatter

        self.successCodes = successCodes
        self.session = NSURLSession(configuration: sessionConfiguration)
        self.request = request

        dispatch_resume(self.clearTimer)
    }

    public convenience init(
        URL: NSURL,
        HTTPMethod: String,
        successCodes: Set<Int> = Set([200, 201, 202, 204]),
        sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(),
        minimumLogLevel: LXLogLevel = .All,
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
        if !self.suspended {
            dispatch_source_cancel(self.clearTimer)
        }
        self.session.finishTasksAndInvalidate()
    }

    public func write(entryString: String) {
        guard let data = entryString.dataUsingEncoding(NSUTF8StringEncoding) else {
            assertionFailure("Failure to create data from entry string")
            return
        }
        self.uploadData(data)
    }

    private func newClearTimer() -> dispatch_source_t {
        return dispatchRepeatingTimer(delay: 5.0, interval: 15.0, tolerance: 5.0, handler: { self.clearCompleted() })
    }

    private func uploadData(data: NSData) {
        dispatch_async(self.lock, {
            let task = self.session.uploadTaskWithRequest(self.request, fromData: data, completionHandler: { _, response, _ in
                if !self.successCodes.contains((response as? NSHTTPURLResponse)?.statusCode ?? -1) {
                    self.uploadData(data)
                }
            })
            if !self.suspended {
                task.resume()
            }
        })
    }

    private func clearCompleted() {
        dispatch_barrier_async(self.lock, {
            self.pending = self.pending.filter({ $0.state == .Running || $0.state == .Suspended })
        })
    }

    public func suspend() {
        if !self.suspended {
            dispatch_source_cancel(self.clearTimer)
            self.suspended = true
            dispatch_barrier_async(self.lock, {
                self.pending.filter({ $0.state == .Running }).map({ task -> Void in task.suspend() })
            })
        }
    }

    public func resume() {
        if self.suspended {
            self.suspended = false
            self.clearTimer = self.newClearTimer()
            dispatch_resume(self.clearTimer)
            dispatch_barrier_async(self.lock, {
                self.pending.filter({ $0.state == .Suspended }).map({ task -> Void in task.resume() })
            })
        }
    }

}


public class LXHTTPJSONEndpoint: LXHTTPEndpoint {

    public init(
        request: NSURLRequest,
        successCodes: Set<Int> = Set([200, 201, 202, 204]),
        sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(),
        minimumLogLevel: LXLogLevel = .All,
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
        successCodes: Set<Int> = Set([200, 201, 202, 204]),
        sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(),
        minimumLogLevel: LXLogLevel = .All,
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
