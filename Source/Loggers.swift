// Loggers.swift
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


/// The main logging API for application code. An instance of this class distributes Log Entries to Endpoints for writing.
public final class LXLogger {
    /// The collection of Endpoints that successfully initialized.
    private let endpoints: [LXEndpoint]

    /**
    Initialize a Logger. Any Endpoints that fail initialization are discarded.

    - parameter endpoints: An array of Endpoints to dispatch Log Entries to.
    */
    public init(endpoints: [LXEndpoint?]) {
        self.endpoints = endpoints.filter({ $0 != nil }).map({ $0! })
        assert(!self.endpoints.isEmpty, "A logger instance has been initialized, but no valid endpoints were provided.")
    }

    /// Initialize a basic Logger that writes to the console (`stdout`) with default settings.
    public convenience init() {
        self.init(endpoints: [LXConsoleEndpoint()])
    }

    /**
    Delivers Log Entries to Endpoints.

    This function filters Endpoints based on their `minimumPriorityLevel` property to deliver Entries only to qualified Endpoints.
    If no Endpoint qualifies, most of the work is skipped.

    After identifying qualified Endpoints, the Log Entry is serialized to a string based on each Endpoint's individual settings.
    Then, it is dispatched to the Endpoint for writing.
    */
    private func log(
        messageBlock: () -> String,
        userInfo: [String: AnyObject],
        level: LXPriorityLevel,
        functionName: String,
        filePath: String,
        lineNumber: Int,
        columnNumber: Int,
        threadID: String = NSString(format: "%p", NSThread.currentThread()) as String,
        threadName: String = NSThread.currentThread().name ?? "",
        isMainThread: Bool = NSThread.currentThread().isMainThread
    ) {
        let timestamp = CFAbsoluteTimeGetCurrent()
        let targetEndpoints = self.endpoints.filter({ $0.minimumPriorityLevel <= level })
        if !targetEndpoints.isEmpty {
            // Resolve the message now, just once
            let message = messageBlock()
            let now = NSDate(timeIntervalSinceReferenceDate: timestamp)
            for endpoint in targetEndpoints {
                let entryString = endpoint.entryFormatter.stringFromEntry(LXLogEntry(
                    message: message,
                    userInfo: userInfo,
                    level: level.description,
                    timestamp: now.timeIntervalSince1970,
                    dateTime: endpoint.dateFormatter.stringFromDate(now),
                    functionName: functionName,
                    filePath: filePath,
                    lineNumber: lineNumber,
                    columnNumber: columnNumber,
                    threadID: threadID,
                    threadName: threadName,
                    isMainThread: isMainThread
                ), appendNewline: endpoint.requiresNewlines)
                endpoint.write(entryString)
            }
        }
    }

    /**
    Log a `Debug` entry.

    - parameter message: The message to log.
    - parameter userInfo: (optional) A dictionary of additional values for endpoints to consider.
    */
    public func debug(
        @autoclosure(escaping) message: () -> String,
        userInfo: [String: AnyObject] = [:],
        functionName: String = __FUNCTION__,
        filePath: String = __FILE__,
        lineNumber: Int = __LINE__,
        columnNumber: Int = __COLUMN__
    ) {
        self.log(message, userInfo: userInfo, level: .Debug, functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /**
    Log an `Info` entry.

    - parameter message: The message to log.
    - parameter userInfo: (optional) A dictionary of additional values for endpoints to consider.
    */
    public func info(
        @autoclosure(escaping) message: () -> String,
        userInfo: [String: AnyObject] = [:],
        functionName: String = __FUNCTION__,
        filePath: String = __FILE__,
        lineNumber: Int = __LINE__,
        columnNumber: Int = __COLUMN__
    ) {
        self.log(message, userInfo: userInfo, level: .Info, functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /**
    Log a `Notice` entry.

    - parameter message: The message to log.
    - parameter userInfo: (optional) A dictionary of additional values for endpoints to consider.
    */
    public func notice(
        @autoclosure(escaping) message: () -> String,
        userInfo: [String: AnyObject] = [:],
        functionName: String = __FUNCTION__,
        filePath: String = __FILE__,
        lineNumber: Int = __LINE__,
        columnNumber: Int = __COLUMN__
    ) {
        self.log(message, userInfo: userInfo, level: .Notice, functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /**
    Log a `Warning` entry.

    - parameter message: The message to log.
    - parameter userInfo: (optional) A dictionary of additional values for endpoints to consider.
    */
    public func warning(
        @autoclosure(escaping) message: () -> String,
        userInfo: [String: AnyObject] = [:],
        functionName: String = __FUNCTION__,
        filePath: String = __FILE__,
        lineNumber: Int = __LINE__,
        columnNumber: Int = __COLUMN__
    ) {
        self.log(message, userInfo: userInfo, level: .Warning, functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /**
    Log an `Error` entry.

    - parameter message: The message to log.
    - parameter userInfo: (optional) A dictionary of additional values for endpoints to consider.
    */
    public func error(
        @autoclosure(escaping) message: () -> String,
        userInfo: [String: AnyObject] = [:],
        functionName: String = __FUNCTION__,
        filePath: String = __FILE__,
        lineNumber: Int = __LINE__,
        columnNumber: Int = __COLUMN__
    ) {
        self.log(message, userInfo: userInfo, level: .Error, functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /**
    Log a `Critical` entry.

    - parameter message: The message to log.
    - parameter userInfo: (optional) A dictionary of additional values for endpoints to consider.
    */
    public func critical(
        @autoclosure(escaping) message: () -> String,
        userInfo: [String: AnyObject] = [:],
        functionName: String = __FUNCTION__,
        filePath: String = __FILE__,
        lineNumber: Int = __LINE__,
        columnNumber: Int = __COLUMN__
    ) {
        self.log(message, userInfo: userInfo, level: .Critical, functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

}
