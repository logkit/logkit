// LogKit.swift
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

/// The version of the LogKit framework currently in use.
private let logKitVersion = "1.0.4"

//MARK: Definitions

/**
A closure that converts a log entry into a string for writing to an endpoint.

:param: entry The log entry to be formatted.

:returns: The entry converted to a string.
*/
public typealias LXLogEntryFormatter = (entry: LXLogEntry) -> String

/// Objects that conform to the `LXLogEndpoint` protocol may be used by an `LXLogger` as log entry destinations.
public protocol LXLogEndpoint {
    /// Only log entries of this level or above will be written to this endpoint.
    var minimumLogLevel: LXLogLevel { get }
    /// The date formatter that this endpoint will use to convert an entry's `dateTime` to a string.
    var dateFormatter: NSDateFormatter { get }
    /// The entry formatter that this endpoint will use to convert an entry to a string.
    var entryFormatter: LXLogEntryFormatter { get }
    /**
    Write the formatted log entry to the endpoint.

    :param: entryString The log entry, after being formatted by the `entryFormatter`.
    */
    func write(entryString: String) -> Void

}

/**
The details of a log entry.

:param: message The message provided.
:param: userInfo A dictionary of additional values to be provided to the entry formatter.
:param: logLevel The name of the entry's log level.
:param: timestamp The number of seconds since the Unix epoch (midnight 1970-01-01 UTC).
:param: dateTime The entry's timestamp as a string formatted by an endpoint's `dateFormatter`.
:param: functionName The function from which the log entry was created.
:param: fileName The name of the source file from which the log entry was created.
:param: filePath The absolute path of the source file from which the log entry was created.
:param: lineNumber The line number in the file from which the log entry was created.
:param: columnNumber The column number in the file from which the log entry was created.
:param: threadID The ID of the thread from which the log entry was created.
:param: threadName The name of the thread from which the log entry was created.
:param: isMainThread Indicates whether the log entry was created on the main thread.
:param: logKitVersion The version of the LogKit framework that generated this entry.
*/
public struct LXLogEntry {

    /// The message provided.
    public let message: String
    /// A dictionary of additional values to be provided to the entry formatter.
    public let userInfo: [String: AnyObject]
    /// The name of the entry's log level.
    public let logLevel: String
    /// The number of seconds since the Unix epoch (midnight 1970-01-01 UTC).
    public let timestamp: Double
    /// The entry's timestamp as a string formatted by an endpoint's `dateFormatter`.
    public let dateTime: String
    /// The function from which the log entry was created.
    public let functionName: String
    /// The absolute path of the source file from which the log entry was created.
    public let filePath: String
    /// The line number in the file from which the log entry was created.
    public let lineNumber: Int
    /// The column number in the file from which the log entry was created.
    public let columnNumber: Int
    /// The ID of the thread from which the log entry was created.
    public let threadID: String
    /// The name of the thread from which the log entry was created.
    public let threadName: String
    /// Indicates whether the log entry was created on the main thread.
    public let isMainThread: Bool
    /// The version of the LogKit framework that generated this entry.
    public let logKitVersion: String

    /// The name of the source file from which the log entry was created.
    public var fileName: String { return self.filePath.lastPathComponent }

}

/// Private extension to facilitate JSON serialization.
private extension LXLogEntry {
    /// Returns log entry as a dictionary. Will replace any top-level `userInfo` items that use one of the reserved names.
    private func asMap() -> [String: AnyObject] {
        var result = self.userInfo
        result["message"] = self.message
        result["logLevel"] = self.logLevel
        result["timestamp"] = self.timestamp
        result["dateTime"] = self.dateTime
        result["functionName"] = self.functionName
        result["fileName"] = self.fileName
        result["filePath"] = self.filePath
        result["lineNumber"] = self.lineNumber
        result["columnNumber"] = self.columnNumber
        result["threadID"] = self.threadID
        result["threadName"] = self.threadName
        result["isMainThread"] = self.isMainThread
        result["logKitVersion"] = self.logKitVersion
        return result
    }

}


//MARK: Log Levels

/**
Logging levels are described below, in order of lowest-to-highest value:

- `All`: Special value that includes all log levels
- `Debug`: Programmer debugging
- `Info`: Programmer information
- `Notice`: General notice
- `Warning`: Event may affect user experience at some point, if not corrected
- `Error`: Event will definitely affect user experience
- `Critical`: Event may crash application
- `None`: Special value that excludes all log levels
*/
public enum LXLogLevel: Int, Comparable, Printable {
    // These levels are designed to match ASL levels
    // https://developer.apple.com/library/mac/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/LoggingErrorsAndWarnings.html
    case All      =  100
    case Debug    =    7
    case Info     =    6
    case Notice   =    5
    case Warning  =    4
    case Error    =    3
    case Critical =    2
    case None     = -100

    /**
    :returns: A string representation of the log level.
    */
    public var description: String {
        switch self {
        case .All:
            return "All"
        case .Debug:
            return "Debug"
        case .Info:
            return "Info"
        case .Notice:
            return "Notice"
        case .Warning:
            return "Warning"
        case .Error:
            return "Error"
        case .Critical:
            return "Critical"
        case .None:
            return "None"
        }
    }

}

/// Determines if two log levels are equal.
public func ==(lhs: LXLogLevel, rhs: LXLogLevel) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

/// Performs a comparison between two log levels.
public func <(lhs: LXLogLevel, rhs: LXLogLevel) -> Bool {
    return lhs.rawValue > rhs.rawValue // Yes, this is reversed
}


//MARK: Default Formatters

/// A formatter block that returns an entry formatted as a string.
private let defaultEntryFormatter: LXLogEntryFormatter = { entry in
    return "\(entry.dateTime) [\(entry.logLevel.uppercaseString)] \(entry.functionName) <\(entry.fileName):\(entry.lineNumber)> \(entry.message)"
}

/// A date formatter that returns a date as a string in a high-precision format, using the UTC timezone.
private let defaultDateFormatter: NSDateFormatter = {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm':'ss'.'SSS"
    dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
    return dateFormatter
}()


//MARK: Endpoints

/// An Abstract Base Class that conforms to the `LXLogEndpoint` protocol. Must be subclassed. Meant to be private; may be removed in future releases.
public class LXLogAbstractEndpoint: LXLogEndpoint {
    /// Only log entries of this level or above will be written to this endpoint.
    public var minimumLogLevel: LXLogLevel
    /// The date formatter that this endpoint will use to convert an entry's `dateTime` to a string.
    public var dateFormatter: NSDateFormatter
    /// The entry formatter that this endpoint will use to convert an entry to a string.
    public var entryFormatter: LXLogEntryFormatter

    /**
    Initialize a log endpoint.

    :param: minimumLogLevel Only log entries of this level or above will be written to this endpoint. Defaults to `All` if omitted.
    :param: dateFormatter The date formatter that this endpoint will use to convert an entry's `dateTime` to a string. Defaults to `defaultDateFormatter` if omitted.
    :param: entryFormatter The entry formatter that this endpoint will use to convert an entry to a string. Defaults to `defaultEntryFormatter` if omitted.

    :returns: An initialized endpoint.
    */
    public init(minimumLogLevel: LXLogLevel = .All, dateFormatter: NSDateFormatter = defaultDateFormatter, entryFormatter: LXLogEntryFormatter = defaultEntryFormatter) {
        self.minimumLogLevel = minimumLogLevel
        self.dateFormatter = dateFormatter
        self.entryFormatter = entryFormatter
    }

    /// This function must be overridden in subclasses. Will `abort` test builds, but `NOOP` silently in shipping builds.
    public func write(entryString: String) {
        assertionFailure("LXAbstractEndpoint is an abstract base class. Please subclass.")
    }

}

/// An endpoint that prints log entries to the console (stdout). Text from multiple threads may become jumbled.
public class LXLogConsoleEndpoint: LXLogAbstractEndpoint {
    /// Writes an entry to the console (stdout).
    public override func write(entryString: String) {
        println(entryString)
    }

}

/**
An endpoint that prints log entries to the console (stdout) one at a time.

Log enties from various threads will be printed in first-in-first-out order without overlapping.
However, entry output may be slightly delayed due to the asynchronous nature of this endpoint.
*/
public class LXLogSerialConsoleEndpoint: LXLogConsoleEndpoint {
    /// Writes an entry to the console (stdout).
    public override func write(entryString: String) {
        if let data = (entryString + "\n").dispatchDataUsingEncoding(NSUTF8StringEncoding) {
            dispatch_write(STDOUT_FILENO, data, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { data, errno in })
        } else {
            assertionFailure("Failure to create dispatch_data_t from entry string")
        }
    }

}

/// An endpoint that writes log entries to a given log file asynchronously.
public class LXLogFileEndpoint: LXLogAbstractEndpoint {
    /// An opportunity for subclasses to modify the file name that will be used. Base method simply returns it's input.
    private class func makeName(#baseName: String) -> String {
        return baseName
    }

    private let channel: dispatch_io_t?

    /**
    Initialize a log endpoint.

    :param: fileURL The URL of the log file. Will be created (along with intermediate directories) if the file does not already exist. Passing `nil` will cause the initializer to fail.
    :param: minimumLogLevel Only log entries of this level or above will be written to this endpoint. Defaults to `All` if omitted.
    :param: dateFormatter The date formatter that this endpoint will use to convert an entry's `dateTime` to a string. Defaults to `defaultDateFormatter` if omitted.
    :param: entryFormatter The entry formatter that this endpoint will use to convert an entry to a string. Defaults to `defaultEntryFormatter` if omitted.

    :returns: An initialized endpoint, or `nil` if the designated file could not be opened.
    */
    public init?(fileURL: NSURL?, minimumLogLevel: LXLogLevel = .All, dateFormatter: NSDateFormatter = defaultDateFormatter, entryFormatter: LXLogEntryFormatter = defaultEntryFormatter) {
        if let
            dirURL = fileURL?.URLByDeletingLastPathComponent,
            fileName = fileURL?.lastPathComponent,
            path = dirURL.URLByAppendingPathComponent(self.dynamicType.makeName(baseName: fileName), isDirectory: false).path
        where
            NSFileManager.defaultManager().createDirectoryAtURL(dirURL, withIntermediateDirectories: true, attributes: nil, error: nil)
        {
            self.channel = dispatch_io_create_with_path(
                DISPATCH_IO_STREAM,
                path,
                O_WRONLY | O_NONBLOCK | O_APPEND | O_CREAT,
                S_IRUSR | S_IWUSR | S_IRGRP,
                dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                { errno in }
            ) as dispatch_io_t?
        } else {
            self.channel = nil
        }
        super.init(minimumLogLevel: minimumLogLevel, dateFormatter: dateFormatter, entryFormatter: entryFormatter)
        if self.channel == nil {
            assertionFailure("File '\(fileURL?.path ?? String())' could not be opened")
            return nil
        }
    }

    /**
    Initialize an endpoint that writes to `log.txt` within `ApplicationSupport/{bundleID}/logs/`.

    :param: minLogLevel Only log entries of this level or above will be written to this endpoint. Defaults to `All` if omitted.
    :param: dateFormatter The date formatter that this endpoint will use to convert an entry's `dateTime` to a string. Defaults to `defaultDateFormatter` if omitted.
    :param: entryFormatter The entry formatter that this endpoint will use to convert an entry to a string. Defaults to `defaultEntryFormatter` if omitted.

    :returns: An initialized endpoint, or `nil` if the requested file could not be opened.
    */
    public convenience init?(minLogLevel: LXLogLevel = .All, dateFormatter: NSDateFormatter = defaultDateFormatter, entryFormatter: LXLogEntryFormatter = defaultEntryFormatter) {
        let fileURL: NSURL?
        if let
            bundleID = NSBundle.mainBundle().bundleIdentifier,
            appSupportURL = (NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask) as? [NSURL])?.first
        {
            fileURL = appSupportURL
                .URLByAppendingPathComponent(bundleID, isDirectory: true)
                .URLByAppendingPathComponent("logs", isDirectory: true)
                .URLByAppendingPathComponent("log.txt", isDirectory: false)
        } else {
            fileURL = nil
        }
        self.init(fileURL: fileURL, minimumLogLevel: minLogLevel, dateFormatter: dateFormatter, entryFormatter: entryFormatter)
    }

    /// Closes the log file, if it is open.
    deinit {
        if let chnl = self.channel {
            dispatch_io_close(chnl, 0)
        }
    }

    /// Writes an entry to the log file.
    public override func write(entryString: String) {
        if let chnl = self.channel, data = (entryString + "\n").dispatchDataUsingEncoding(NSUTF8StringEncoding) {
            dispatch_io_write(chnl, 0, data, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { done, data, errno in })
        } else {
            assertionFailure("Failure to create dispatch_data_t from entry string")
        }
    }

}

/// An endpoint that writes log entries to a given log file asynchronously. A datestamp will be prepended to the file's name.
public class LXLogDatedFileEndpoint: LXLogFileEndpoint {

    /// Prepends a datestamp to the base file name in the format `yyyy-MM-dd_{fileName}`.
    override private class func makeName(#baseName: String) -> String {
        let fileNameDateFormatter = NSDateFormatter()
        fileNameDateFormatter.dateFormat = "yyyy'-'MM'-'dd"
        fileNameDateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        return "\(fileNameDateFormatter.stringFromDate(NSDate()))_\(baseName)"
    }

}

/// An endpoint that writes log entries to an HTTP service.
public class LXLogHTTPEndpoint: LXLogAbstractEndpoint {
    /// An opportunity for subclasses to modify the request that will be used.
    private class func makeRequest(URL: NSURL, HTTPMethod: String) -> NSMutableURLRequest {
        let request = NSMutableURLRequest(URL: URL)
        request.HTTPMethod = HTTPMethod
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        return request
    }

    private let session: NSURLSession
    private let request: NSURLRequest
    private let successCodes: Set<Int>
    private let timer: dispatch_source_t = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
    private let lockQueue: dispatch_queue_t = dispatch_queue_create("lx-HTTPEndpoint-lockQueue", DISPATCH_QUEUE_SERIAL)
    private var pendingUploads: [NSData] = []

    /**
    Initialize a log endpoint.

    :param: URL The URL to upload the log entry to.
    :param: HTTPMethod The HTTP request method to be used when uploading log entries.
    :param: successCodes A set of HTTP response codes that will be considered success when returned from HTTP service. Defaults to `{200, 201, 202, 204}` if omitted.
    :param: sessionConfiguration The configuration to be used when initializating this endpoint's URL Session. Defaults to `NSURLSessionConfiguration.defaultSessionConfiguration()` if omitted.
    :param: minimumLogLevel Only log entries of this level or above will be written to this endpoint. Defaults to `All` if omitted.
    :param: dateFormatter The date formatter that this endpoint will use to convert an entry's `dateTime` to a string. Defaults to `defaultDateFormatter` if omitted.
    :param: entryFormatter The entry formatter that this endpoint will use to convert an entry to a string. Defaults to `defaultEntryFormatter` if omitted.

    :returns: An initialized endpoint.
    */
    public init(
        URL: NSURL,
        HTTPMethod: String,
        successCodes: Set<Int> = Set([200, 201, 202, 204]),
        sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(),
        minimumLogLevel: LXLogLevel = .All,
        dateFormatter: NSDateFormatter = defaultDateFormatter,
        entryFormatter: LXLogEntryFormatter = defaultEntryFormatter
    ) {
        self.successCodes = successCodes
        self.session = NSURLSession(configuration: sessionConfiguration)
        self.request = self.dynamicType.makeRequest(URL, HTTPMethod: HTTPMethod)
        super.init(minimumLogLevel: minimumLogLevel, dateFormatter: dateFormatter, entryFormatter: entryFormatter)
        dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC, 15 * NSEC_PER_SEC)
        dispatch_source_set_event_handler(self.timer, {
            self.uploadPending()
        })
        dispatch_resume(self.timer)
    }

    deinit {
        dispatch_source_cancel(self.timer)
        self.session.finishTasksAndInvalidate()
    }

    /// Writes an entry to an HTTP service.
    public override func write(entryString: String) {
        self.queueEntryForUpload(entryString)
    }

    /// Add a log entry to the pending queue.
    private func queueEntryForUpload(entryString: String) {
        dispatch_async(self.lockQueue, {
            if let data = entryString.dataUsingEncoding(NSUTF8StringEncoding) {
                self.pendingUploads.append(data)
                self.uploadPending()
            } else {
                assertionFailure("Failure to create NSData from entry string")
            }
        })
    }

    /**
    Attempts to upload all pending entries to the HTTP service. If the HTTP service does not return a "success" status
    code (as defined by `self.successCodes`), the entry will be returned to the pending queue to be tried again later.
    */
    private func uploadPending() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            dispatch_sync(self.lockQueue, {
                for data in self.pendingUploads {
                    let task = self.session.uploadTaskWithRequest(self.request, fromData: data, completionHandler: { body, response, error in
                        if !self.successCodes.contains( (response as? NSHTTPURLResponse)?.statusCode ?? -1 ) {
                            dispatch_async(self.lockQueue, { self.pendingUploads.append(data) })
                        }
                    })
                    task.resume()
                }
                self.pendingUploads.removeAll(keepCapacity: false)
            })
        })
    }

}

/// An endpoint that writes log entries to an HTTP service in JSON format.
public class LXLogHTTPJSONEndpoint: LXLogHTTPEndpoint {
    /// An opportunity for subclasses to modify the request that will be used. Sets `Content-Type` header to `application/json`.
    private override class func makeRequest(URL: NSURL, HTTPMethod: String) -> NSMutableURLRequest {
        let request = super.makeRequest(URL, HTTPMethod: HTTPMethod)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    /**
    Initialize a log endpoint. Log entries will be converted to a JSON object automatically.

    :param: URL The URL to upload the log entry to.
    :param: HTTPMethod The HTTP request method to be used when uploading log entries.
    :param: successCodes A set of HTTP response codes that will be considered success when returned from HTTP service. Defaults to `{200, 201, 202, 204}` if omitted.
    :param: sessionConfiguration The configuration to be used when initializating this endpoint's URL Session. Defaults to `NSURLSessionConfiguration.defaultSessionConfiguration()` if omitted.
    :param: minimumLogLevel Only log entries of this level or above will be written to this endpoint. Defaults to `All` if omitted.
    :param: dateFormatter The date formatter that this endpoint will use to convert an entry's `dateTime` to a string. Defaults to `defaultDateFormatter` if omitted.

    :returns: An initialized endpoint.
    */
    public init(
        URL: NSURL,
        HTTPMethod: String,
        successCodes: Set<Int> = Set([200, 201, 202, 204]),
        sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(),
        minimumLogLevel: LXLogLevel = .All,
        dateFormatter: NSDateFormatter = defaultDateFormatter
    ) {
        super.init(
            URL: URL,
            HTTPMethod: HTTPMethod,
            successCodes: successCodes,
            sessionConfiguration: sessionConfiguration,
            minimumLogLevel: minimumLogLevel,
            dateFormatter: dateFormatter,
            entryFormatter: { entry in
                if let
                    data = NSJSONSerialization.dataWithJSONObject(entry.asMap(), options: nil, error: nil),
                    json = NSString(data: data, encoding: NSUTF8StringEncoding)
                {
                    return json as String
                } else {
                    assertionFailure("Log entry could not be serialized to JSON")
                    return ""
                }
            }
        )
    }

}


//MARK: Logger


/// The main logging API for application code. An instance of this class dispatches log entries to logging endpoints.
public final class LXLogger {
    /// The collection of log endpoints that successfully initialized.
    private let endpoints: [LXLogEndpoint]

    /**
    Initialize a logger.

    :param: endpoints An array of log endpoints to output entries to.

    :returns: An initialized logger populated with each of the provided endpoints. Any endpoints that fail initialization are discarded.
    */
    public init(endpoints: [LXLogEndpoint?]) {
        self.endpoints = endpoints.filter({ $0 != nil }).map({ $0! })
        assert(!self.endpoints.isEmpty, "A logger instance has been initialized, but no valid endpoints were provided.")
    }

    /// Initialize a basic logger that writes to the console (stdout) with default settings.
    public convenience init() {
        self.init(endpoints: [LXLogConsoleEndpoint()])
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
                let entryString = endpoint.entryFormatter(entry: LXLogEntry(
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
                ))
                endpoint.write(entryString)
            }
        }
    }

    /**
    Log a `Debug` entry. Exclude all arguments except `message`.

    :param: message The message to log.
    */
    public func debug(
        @autoclosure(escaping) message: () -> String,
        functionName: String = __FUNCTION__,
        filePath: String = __FILE__,
        lineNumber: Int = __LINE__,
        columnNumber: Int = __COLUMN__
    ) {
        self.debug(message, userInfo: [:], functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /**
    Log a `Debug` entry. Exclude all arguments except `message` and `userInfo`.

    :param: message The message to log.
    :param: userInfo A dictionary of additional values for endpoints to consider.
    */
    public func debug(
        @autoclosure(escaping) message: () -> String,
        userInfo: [String: AnyObject],
        functionName: String = __FUNCTION__,
        filePath: String = __FILE__,
        lineNumber: Int = __LINE__,
        columnNumber: Int = __COLUMN__
    ) {
        self.log(message, userInfo: userInfo, level: .Debug, functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /**
    Log an `Info` entry. Exclude all arguments except `message`.

    :param: message The message to log.
    */
    public func info(
        @autoclosure(escaping) message: () -> String,
        functionName: String = __FUNCTION__,
        filePath: String = __FILE__,
        lineNumber: Int = __LINE__,
        columnNumber: Int = __COLUMN__
    ) {
        self.info(message, userInfo: [:], functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /**
    Log an `Info` entry. Exclude all arguments except `message` and `userInfo`.

    :param: message The message to log.
    :param: userInfo A dictionary of additional values for endpoints to consider.
    */
    public func info(
        @autoclosure(escaping) message: () -> String,
        userInfo: [String: AnyObject],
        functionName: String = __FUNCTION__,
        filePath: String = __FILE__,
        lineNumber: Int = __LINE__,
        columnNumber: Int = __COLUMN__
    ) {
        self.log(message, userInfo: userInfo, level: .Info, functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /**
    Log a `Notice` entry. Exclude all arguments except `message`.

    :param: message The message to log.
    */
    public func notice(
        @autoclosure(escaping) message: () -> String,
        functionName: String = __FUNCTION__,
        filePath: String = __FILE__,
        lineNumber: Int = __LINE__,
        columnNumber: Int = __COLUMN__
    ) {
        self.notice(message, userInfo: [:], functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /**
    Log a `Notice` entry. Exclude all arguments except `message` and `userInfo`.

    :param: message The message to log.
    :param: userInfo A dictionary of additional values for endpoints to consider.
    */
    public func notice(
        @autoclosure(escaping) message: () -> String,
        userInfo: [String: AnyObject],
        functionName: String = __FUNCTION__,
        filePath: String = __FILE__,
        lineNumber: Int = __LINE__,
        columnNumber: Int = __COLUMN__
    ) {
        self.log(message, userInfo: userInfo, level: .Notice, functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /**
    Log a `Warning` entry. Exclude all arguments except `message`.

    :param: message The message to log.
    */
    public func warning(
        @autoclosure(escaping) message: () -> String,
        functionName: String = __FUNCTION__,
        filePath: String = __FILE__,
        lineNumber: Int = __LINE__,
        columnNumber: Int = __COLUMN__
    ) {
        self.warning(message, userInfo: [:], functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /**
    Log a `Warning` entry. Exclude all arguments except `message` and `userInfo`.

    :param: message The message to log.
    :param: userInfo A dictionary of additional values for endpoints to consider.
    */
    public func warning(
        @autoclosure(escaping) message: () -> String,
        userInfo: [String: AnyObject],
        functionName: String = __FUNCTION__,
        filePath: String = __FILE__,
        lineNumber: Int = __LINE__,
        columnNumber: Int = __COLUMN__
    ) {
        self.log(message, userInfo: userInfo, level: .Warning, functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /**
    Log an `Error` entry. Exclude all arguments except `message`.

    :param: message The message to log.
    */
    public func error(
        @autoclosure(escaping) message: () -> String,
        functionName: String = __FUNCTION__,
        filePath: String = __FILE__,
        lineNumber: Int = __LINE__,
        columnNumber: Int = __COLUMN__
    ) {
        self.error(message, userInfo: [:], functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /**
    Log an `Error` entry. Exclude all arguments except `message` and `userInfo`.

    :param: message The message to log.
    :param: userInfo A dictionary of additional values for endpoints to consider.
    */
    public func error(
        @autoclosure(escaping) message: () -> String,
        userInfo: [String: AnyObject],
        functionName: String = __FUNCTION__,
        filePath: String = __FILE__,
        lineNumber: Int = __LINE__,
        columnNumber: Int = __COLUMN__
    ) {
        self.log(message, userInfo: userInfo, level: .Error, functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /**
    Log a `Critical` entry. Exclude all arguments except `message`.

    :param: message The message to log.
    */
    public func critical(
        @autoclosure(escaping) message: () -> String,
        functionName: String = __FUNCTION__,
        filePath: String = __FILE__,
        lineNumber: Int = __LINE__,
        columnNumber: Int = __COLUMN__
    ) {
        self.critical(message, userInfo: [:], functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

    /**
    Log a `Critical` entry. Exclude all arguments except `message` and `userInfo`.

    :param: message The message to log.
    :param: userInfo A dictionary of additional values for endpoints to consider.
    */
    public func critical(
        @autoclosure(escaping) message: () -> String,
        userInfo: [String: AnyObject],
        functionName: String = __FUNCTION__,
        filePath: String = __FILE__,
        lineNumber: Int = __LINE__,
        columnNumber: Int = __COLUMN__
    ) {
        self.log(message, userInfo: userInfo, level: .Critical, functionName: functionName, filePath: filePath, lineNumber: lineNumber, columnNumber: columnNumber)
    }

}

extension String {
    /// Returns a dispatch_data_t object containing a representation of the String encoded using a given encoding.
    func dispatchDataUsingEncoding(encoding: NSStringEncoding) -> dispatch_data_t? {
        if let nData = self.dataUsingEncoding(encoding), dData = dispatch_data_create(nData.bytes, nData.length, nil, nil) {
            return dData
        } else {
            return nil
        }
    }

}
