// Loggers.swift
//
// Copyright (c) 2015 - 2016, Justin Pawela & The LogKit Project
// http://www.logkit.info/
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
    fileprivate let endpoints: [LXEndpoint]

    /// Initialize a Logger. Any Endpoints that fail initialization are discarded.
    ///
    /// - parameter endpoints: An array of Endpoints to dispatch Log Entries to.
    public init(endpoints: [LXEndpoint?]) {
        self.endpoints = endpoints.filter({ $0 != nil }).map({ $0! })
        assert(!self.endpoints.isEmpty, "A logger instance has been initialized, but no valid Endpoints were provided.")
    }

    /// Initialize a basic Logger that writes to the console (`stderr`) with default settings.
    public convenience init() {
        self.init(endpoints: [LXConsoleEndpoint()])
    }

    /// Delivers Log Entries to Endpoints.
    ///
    /// This function filters Endpoints based on their `minimumPriorityLevel` property to deliver Entries only to
    /// qualified Endpoints. If no Endpoint qualifies, most of the work is skipped.
    ///
    /// After identifying qualified Endpoints, the Log Entry is serialized to a string based on each Endpoint's
    /// individual settings. Then, it is dispatched to the Endpoint for writing.
    fileprivate func log(
        _ messageBlock: () -> String,
        userInfo: [String: AnyObject],
        level: LXPriorityLevel,
        functionName: String,
        filePath: String,
        lineNumber: Int,
        columnNumber: Int,
        threadID: String = NSString(format: "%p", Thread.current) as String,
        threadName: String = Thread.current.name ?? "",
        isMainThread: Bool = Thread.current.isMainThread
    ) {
        let timestamp = CFAbsoluteTimeGetCurrent()
        let targetEndpoints = self.endpoints.filter({ $0.minimumPriorityLevel <= level })
        if !targetEndpoints.isEmpty {
            // Resolve the message now, just once
            let message = messageBlock()
            let now = Date(timeIntervalSinceReferenceDate: timestamp)
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

    /// Log a `Debug` entry.
    ///
    /// - parameter message:  The message to log.
    /// - parameter userInfo: A dictionary of additional values for Endpoints to consider.
    public func debug(
        _ message: @autoclosure @escaping () -> String,
        userInfo: [String: AnyObject] = [:],
        functionName: String = #function,
        filePath: String = #file,
        lineNumber: Int = #line,
        columnNumber: Int = #column
    ) {
        self.log(message, userInfo: userInfo, level: .debug, functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /// Log an `Info` entry.
    ///
    /// - parameter message:  The message to log.
    /// - parameter userInfo: A dictionary of additional values for Endpoints to consider.
    public func info(
        _ message: @autoclosure @escaping () -> String,
        userInfo: [String: AnyObject] = [:],
        functionName: String = #function,
        filePath: String = #file,
        lineNumber: Int = #line,
        columnNumber: Int = #column
    ) {
        self.log(message, userInfo: userInfo, level: .info, functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /// Log a `Notice` entry.
    ///
    /// - parameter message:  The message to log.
    /// - parameter userInfo: A dictionary of additional values for Endpoints to consider.
    public func notice(
        _ message: @autoclosure @escaping () -> String,
        userInfo: [String: AnyObject] = [:],
        functionName: String = #function,
        filePath: String = #file,
        lineNumber: Int = #line,
        columnNumber: Int = #column
    ) {
        self.log(message, userInfo: userInfo, level: .notice, functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /// Log a `Warning` entry.
    ///
    /// - parameter message:  The message to log.
    /// - parameter userInfo: A dictionary of additional values for Endpoints to consider.
    public func warning(
        _ message: @autoclosure @escaping () -> String,
        userInfo: [String: AnyObject] = [:],
        functionName: String = #function,
        filePath: String = #file,
        lineNumber: Int = #line,
        columnNumber: Int = #column
    ) {
        self.log(message, userInfo: userInfo, level: .warning, functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /// Log an `Error` entry.
    ///
    /// - parameter message:  The message to log.
    /// - parameter userInfo: A dictionary of additional values for Endpoints to consider.
    public func error(
        _ message: @autoclosure @escaping () -> String,
        userInfo: [String: AnyObject] = [:],
        functionName: String = #function,
        filePath: String = #file,
        lineNumber: Int = #line,
        columnNumber: Int = #column
    ) {
        self.log(message, userInfo: userInfo, level: .error, functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /// Log a `Critical` entry.
    ///
    /// - parameter message:  The message to log.
    /// - parameter userInfo: A dictionary of additional values for Endpoints to consider.
    public func critical(
        _ message: @autoclosure @escaping () -> String,
        userInfo: [String: AnyObject] = [:],
        functionName: String = #function,
        filePath: String = #file,
        lineNumber: Int = #line,
        columnNumber: Int = #column
    ) {
        self.log(message, userInfo: userInfo, level: .critical, functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

}
