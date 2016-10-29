// Entries.swift
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


/// The details of a Log Entry.
///
/// - parameter       logKitVersion: The version of the LogKit framework that generated this Entry.
/// - parameter             message: The message provided during the logging call.
/// - parameter            userInfo: A set of additional values to be provided to each Endpoint's `entryFormatter`.
/// - parameter               level: The name of the Entry's Priority Level.
/// - parameter           timestamp: The number of seconds since the Unix epoch (midnight 1970-01-01 UTC).
/// - parameter            dateTime: The Entry's timestamp as a string serialized by an Endpoint's `dateFormatter`.
/// - parameter        functionName: The function from which the Log Entry was created.
/// - parameter            fileName: The name of the source file from which the Log Entry was created.
/// - parameter            filePath: The absolute path of the source file from which the Log Entry was created.
/// - parameter          lineNumber: The line number in the file from which the Log Entry was created.
/// - parameter        columnNumber: The column number in the file from which the Log Entry was created.
/// - parameter            threadID: The ID of the thread from which the Log Entry was created.
/// - parameter          threadName: The name of the thread from which the Log Entry was created.
/// - parameter        isMainThread: An indicator of whether the Log Entry was created on the main thread.
/// - parameter     osVersionString: A description of the operating system, including its name and version.
/// - parameter      osMajorVersion: The major version number of the operating system.
/// - parameter      osMinorVersion: The minor version number of the operating system.
/// - parameter      osPatchVersion: The patch version number of the operating system.
/// - parameter      osBuildVersion: The build version string of the operating system.
/// - parameter            bundleID: The bundle ID of the host application.
/// - parameter         deviceModel: The model of the device running the application.
/// - parameter          deviceType: The type of the device running the application.
/// - parameter      deviceVendorID: The vendor ID of the device running the application (if available).
/// - parameter deviceAdvertisingID: The advertising ID of the device running the application (if available).
public struct LXLogEntry {

    /// The version of the LogKit framework that generated this Entry.
    public let logKitVersion: String = LK_LOGKIT_VERSION
    /// The message provided during the logging call.
    public let message: String
    /// A dictionary of additional values to be provided to each Endpoint's `entryFormatter`.
    public let userInfo: [String: AnyObject]
    /// The name of the Entry's Priority Level.
    public let level: String
    /// The number of seconds since the Unix epoch (midnight 1970-01-01 UTC).
    public let timestamp: Double
    /// The Entry's timestamp as a string serialized by an Endpoint's `dateFormatter`.
    public let dateTime: String
    /// The function from which the Log Entry was created.
    public let functionName: String
    /// The absolute path of the source file from which the Log Entry was created.
    public let filePath: String
    /// The line number in the file from which the Log Entry was created.
    public let lineNumber: Int
    /// The column number in the file from which the Log Entry was created.
    public let columnNumber: Int
    /// The ID of the thread from which the Log Entry was created.
    public let threadID: String
    /// The name of the thread from which the Log Entry was created.
    public let threadName: String
    /// An indicator of whether the Log Entry was created on the main thread.
    public let isMainThread: Bool
    /// A description of the operating system, including its name and version.
    public let osVersionString: String = LK_DEVICE_OS.description
    /// The major version number of the operating system.
    public let osMajorVersion: Int = LK_DEVICE_OS.majorVersion
    /// The minor version number of the operating system.
    public let osMinorVersion: Int = LK_DEVICE_OS.minorVersion
    /// The patch version number of the operating system.
    public let osPatchVersion: Int = LK_DEVICE_OS.patchVersion
    /// The build version string of the operating system.
    public let osBuildVersion: String = LK_DEVICE_OS.buildVersion
    /// The bundle ID of the host application.
    public let bundleID: String = LK_BUNDLE_ID
    /// The model of the device running the application.
    public let deviceModel: String = LK_DEVICE_MODEL
    /// The type of the device running the application.
    public let deviceType: String = LK_DEVICE_TYPE
    /// The vendor ID of the device running the application (if available).
    public let deviceVendorID: String = LK_DEVICE_IDS.vendor
    /// The advertising ID of the device running the application (if available).
    public let deviceAdvertisingID: String = LK_DEVICE_IDS.advertising

    /// The name of the source file from which the Log Entry was created.
    public var fileName: String { return (self.filePath as NSString).lastPathComponent }

}


/// Private extension to facilitate JSON serialization.
internal extension LXLogEntry {

    /// Returns the Log Entry as a dictionary.
    internal func asMap() -> [String: AnyObject] {
        return [
            "logKitVersion": self.logKitVersion as AnyObject,
            "message": self.message as AnyObject,
            "userInfo": self.userInfo as AnyObject,
            "level": self.level as AnyObject,
            "timestamp": self.timestamp as AnyObject,
            "dateTime": self.dateTime as AnyObject,
            "functionName": self.functionName as AnyObject,
            "fileName": self.fileName as AnyObject,
            "filePath": self.filePath as AnyObject,
            "lineNumber": self.lineNumber as AnyObject,
            "columnNumber": self.columnNumber as AnyObject,
            "threadID": self.threadID as AnyObject,
            "threadName": self.threadName as AnyObject,
            "isMainThread": self.isMainThread as AnyObject,
            "osVersionString": self.osVersionString as AnyObject,
            "osMajorVersion": self.osMajorVersion as AnyObject,
            "osMinorVersion": self.osMinorVersion as AnyObject,
            "osPatchVersion": self.osPatchVersion as AnyObject,
            "osBuildVersion": self.osBuildVersion as AnyObject,
            "bundleID": self.bundleID as AnyObject,
            "deviceModel": self.deviceModel as AnyObject,
            "deviceType": self.deviceType as AnyObject,
            "deviceVendorID": self.deviceVendorID as AnyObject,
            "deviceAdvertisingID": self.deviceAdvertisingID as AnyObject,
        ]
    }

}
