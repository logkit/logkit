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


public final class LXLogger {
    /// The collection of log endpoints that successfully initialized.
    private let endpoints: [LXEndpoint]

    /**
    Initialize a logger.

    :param: endpoints An array of log endpoints to output entries to.

    :returns: An initialized logger populated with each of the provided endpoints. Any endpoints that fail initialization are discarded.
    */
    public init(endpoints: [LXEndpoint?]) {
        self.endpoints = endpoints.filter({ $0 != nil }).map({ $0! })
        assert(!self.endpoints.isEmpty, "A logger instance has been initialized, but no valid endpoints were provided.")
    }

    /// Initialize a basic logger that writes to the console (stdout) with default settings.
    public convenience init() {
        self.init(endpoints: [LXConsoleEndpoint()])
    }

    /**
    Delivers log entries to endpoints.

    This function filters endpoints based on their `minimumLogLevel` property to deliver entries only to qualified endpoints.
    If no endpoint qualifies, most of the work is skipped.

    After identifying qualified endpoints, the entry is converted to a string based on each endpoint's settings.
    Then, it is output to the endpoint.
    */
    private func log(
        messageBlock: () -> String,
        userInfo: [String: AnyObject],
        level: LXLogLevel,
        functionName: String,
        filePath: String,
        lineNumber: Int,
        columnNumber: Int,
        threadID: String = NSString(format: "%p", NSThread.currentThread()) as String,
        threadName: String = NSThread.currentThread().name ?? "",
        isMainThread: Bool = NSThread.currentThread().isMainThread
    ) {
        let timestamp = CFAbsoluteTimeGetCurrent()
        let targetEndpoints = self.endpoints.filter({ $0.minimumLogLevel <= level })
        if !targetEndpoints.isEmpty {
            // Resolve the message now, just once
            let message = messageBlock()
            let now = NSDate(timeIntervalSinceReferenceDate: timestamp)
            for endpoint in targetEndpoints {
                let entryString = endpoint.entryFormatter.stringFromEntry(LXLogEntry(
                    message: message,
                    userInfo: userInfo,
                    logLevel: level.description,
                    timestamp: now.timeIntervalSince1970,
                    dateTime: endpoint.dateFormatter.stringFromDate(now),
                    functionName: functionName,
                    filePath: filePath,
                    lineNumber: lineNumber,
                    columnNumber: columnNumber,
                    threadID: threadID,
                    threadName: threadName,
                    isMainThread: isMainThread,
                    logKitVersion: logKitVersion
                ), appendNewline: endpoint.requiresNewlines)
                endpoint.write(entryString)
            }
        }
    }

    /**
    Log a `Debug` entry. Exclude all arguments except `message` and `userInfo`.

    :param: message The message to log.
    :param: userInfo A dictionary of additional values for endpoints to consider.
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
    Log an `Info` entry. Exclude all arguments except `message` and `userInfo`.

    :param: message The message to log.
    :param: userInfo A dictionary of additional values for endpoints to consider.
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
    Log a `Notice` entry. Exclude all arguments except `message` and `userInfo`.

    :param: message The message to log.
    :param: userInfo A dictionary of additional values for endpoints to consider.
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
    Log a `Warning` entry. Exclude all arguments except `message` and `userInfo`.

    :param: message The message to log.
    :param: userInfo A dictionary of additional values for endpoints to consider.
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
    Log an `Error` entry. Exclude all arguments except `message` and `userInfo`.

    :param: message The message to log.
    :param: userInfo A dictionary of additional values for endpoints to consider.
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
    Log a `Critical` entry. Exclude all arguments except `message` and `userInfo`.

    :param: message The message to log.
    :param: userInfo A dictionary of additional values for endpoints to consider.
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
