// Entries.swift
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
    public var fileName: String { return (self.filePath as NSString).lastPathComponent }
    
}


/// Private extension to facilitate JSON serialization.
internal extension LXLogEntry {
    /// Returns log entry as a dictionary. Will replace any top-level `userInfo` items that use one of the reserved names.
    internal func asMap() -> [String: AnyObject] {
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
