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
    public let level: String
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
    public let logKitVersion: String = LK_LOGKIT_VERSION

    public let osVersionString: String = LK_DEVICE_OS.decription
    public let osMajorVersion: Int = LK_DEVICE_OS.majorVersion
    public let osMinorVersion: Int = LK_DEVICE_OS.minorVersion
    public let osPatchVersion: Int = LK_DEVICE_OS.patchVersion
    public let osBuildVersion: String = LK_DEVICE_OS.buildVersion
    public let bundleID: String = LK_BUNDLE_ID
    public let deviceModel: String = LK_DEVICE_MODEL
    public let deviceVendorID: String = LK_DEVICE_IDS.vendor
    public let deviceAdvertisingID: String = LK_DEVICE_IDS.advertising

    /// The name of the source file from which the log entry was created.
    public var fileName: String { return (self.filePath as NSString).lastPathComponent }
    
}


/// Private extension to facilitate JSON serialization.
internal extension LXLogEntry {
    /// Returns log entry as a dictionary. Will replace any top-level `userInfo` items that use one of the reserved names.
    internal func asMap() -> [String: AnyObject] {
        return [
            "userInfo": self.userInfo,
            "message": self.message,
            "level": self.level,
            "timestamp": self.timestamp,
            "dateTime": self.dateTime,
            "functionName": self.functionName,
            "fileName": self.fileName,
            "filePath": self.filePath,
            "lineNumber": self.lineNumber,
            "columnNumber": self.columnNumber,
            "threadID": self.threadID,
            "threadName": self.threadName,
            "isMainThread": self.isMainThread,
            "logKitVersion": self.logKitVersion,
            "osVersionString": self.osVersionString,
            "osMajorVersion": self.osMajorVersion,
            "osMinorVersion": self.osMinorVersion,
            "osPatchVersion": self.osPatchVersion,
            "osBuildVersion": self.osBuildVersion,
            "bundleID": self.bundleID,
            "deviceModel": self.deviceModel,
            "deviceVendorID": self.deviceVendorID,
            "deviceAdvertisingID": self.deviceAdvertisingID,
        ]
    }

}
