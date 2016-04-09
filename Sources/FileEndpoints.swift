// FileEndpoints.swift
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


/// This notification is posted whenever a FileEndpoint-family Endpoint instance is about to rotate to a new log file.
///
/// The notification's `object` is the actual Endpoint instance that is rotating files. The `userInfo` dictionary
/// contains the current and next URLs, at the `LXFileEndpointRotationCurrentURLKey` and
/// `LXFileEndpointRotationNextURLKey` keys, respectively.
///
/// This notification is send _before_ the rotation occurs.
public let LXFileEndpointWillRotateFilesNotification: String = "info.logkit.endpoint.fileEndpoint.willRotateFiles"

/// This notification is posted whenever a FileEndpoint-family Endpoint instance has completed rotating to a new log
/// file.
///
/// The notification's `object` is the actual Endpoint instance that is rotating files. The `userInfo` dictionary
/// contains the current and previous URLs, at the `LXFileEndpointRotationCurrentURLKey` and
/// `LXFileEndpointRotationPreviousURLKey` keys, respectively.
///
/// This notification is send _after_ the rotation occurs, but _before_ any pending Log Entries have been written to
/// the new file.
public let LXFileEndpointDidRotateFilesNotification:  String = "info.logkit.endpoint.fileEndpoint.didRotateFiles"

/// The value found at this key is the `NSURL` of the sender's previous log file.
public let LXFileEndpointRotationPreviousURLKey:      String = "info.logkit.endpoint.fileEndpoint.previousURL"

/// The value found at this key is the `NSURL` of the sender's current log file.
public let LXFileEndpointRotationCurrentURLKey:       String = "info.logkit.endpoint.fileEndpoint.currentURL"

/// The value found at this key is the `NSURL` of the sender's next log file.
public let LXFileEndpointRotationNextURLKey:          String = "info.logkit.endpoint.fileEndpoint.nextURL"


/// The default file to use when logging: `log.txt`
private let defaultLogFileURL: NSURL? = LK_DEFAULT_LOG_DIRECTORY?.URLByAppendingPathComponent("log.txt", isDirectory: false)

/// A private UTC-based calendar used in date comparisons.
private let UTCCalendar: NSCalendar = {
//TODO: this is a cheap hack because .currentCalendar() compares dates based on local TZ
    let cal = NSCalendar.currentCalendar().copy() as! NSCalendar
    cal.timeZone = NSTimeZone(forSecondsFromGMT: 0)
    return cal
}()


private extension NSFileManager {

    /// Attempts to read a given file's metadata and convert it to an `LXFileProperties` instance.
    ///
    /// - parameter path: The path of the file to be examined.
    ///
    /// - returns: An `LXFileProperties` instance if successful.
    ///
    /// - throws: If the attributes of file cannot be read.
    private func propertiesOfFileAtPath(path: String) throws -> LXFileProperties {
        let attributes = try NSFileManager.defaultManager().attributesOfItemAtPath(path)
        return LXFileProperties(
            size: (attributes[NSFileSize] as? NSNumber)?.unsignedLongLongValue,
            modified: (attributes[NSFileModificationDate] as? NSDate)?.timeIntervalSinceReferenceDate
        )
    }

}


/// A collection of properties representing file metadata.
///
/// - parameter size:     The size of the file in bytes.
/// - parameter modified: An `NSTimeInterval` representing the file's modification timestamp.
private struct LXFileProperties {
    let size: UIntMax?
    let modified: NSTimeInterval?
}


//MARK: Log File Wrapper

/// A wrapper for a log file.
private class LXLogFile {

    private let lockQueue: dispatch_queue_t = dispatch_queue_create("logFile-Lock", DISPATCH_QUEUE_SERIAL)
    private let handle: NSFileHandle
    private let path: String
    private var privateByteCounter: UIntMax?
    private var privateModificationTracker: NSTimeInterval?

    /// Open a log file.
    private init(path: String, handle: NSFileHandle, appending: Bool) {
        self.path = path
        self.handle = handle

        if appending {
            self.privateByteCounter = UIntMax(self.handle.seekToEndOfFile())
        } else {
            self.handle.truncateFileAtOffset(0)
            self.privateByteCounter = 0
        }

        self.privateModificationTracker = (try? NSFileManager.defaultManager().propertiesOfFileAtPath(path))?.modified
    }

    /// Initialize a log file. `throws` if the file cannot be accessed.
    ///
    /// - parameter URL:          The URL of the log file.
    /// - parameter shouldAppend: Indicates whether new data should be appended to existing data in the file, or if
    ///                           the file should be truncated when opened.
    /// - throws: `NSError` with domain `NSURLErrorDomain`
    convenience init(URL: NSURL, shouldAppend: Bool) throws {
        try NSFileManager.defaultManager().ensureFile(at: URL)
        guard let path = URL.path else {
            assertionFailure("Invalid path: \(URL.absoluteString)")
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSURLErrorKey: URL])
        }
        guard let handle = try? NSFileHandle(forWritingToURL: URL) else {
            assertionFailure("Error opening log file at path: \(URL.absoluteString)")
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotOpenFile, userInfo: [NSURLErrorKey: URL])
        }
        self.init(path: path, handle: handle, appending: shouldAppend)
    }

    /// Clean up.
    deinit {
        dispatch_barrier_sync(self.lockQueue, {
            self.handle.synchronizeFile()
            self.handle.closeFile()
        })
    }

    /// The size of this log file in bytes.
    var sizeInBytes: UIntMax? {
        var size: UIntMax?
        dispatch_sync(self.lockQueue, { size = self.privateByteCounter })
        return size
    }

    /// The date when this log file was last modified.
    var modificationDate: NSDate? {
        var interval: NSTimeInterval?
        dispatch_sync(self.lockQueue, { interval = self.privateModificationTracker })
        return interval == nil ? nil : NSDate(timeIntervalSinceReferenceDate: interval!)
    }

//    private var properties: LXFileProperties? {
//        var props: LXFileProperties?
//        dispatch_sync(self.lockQueue, {
//            do { props = try NSFileManager.defaultManager().propertiesOfFileAtPath(self.path) } catch {}
//        })
//        return props
//    }

    /// Write data to this log file.
    func writeData(data: NSData) {
        dispatch_async(self.lockQueue, {
            self.handle.writeData(data)
            self.privateByteCounter = (self.privateByteCounter ?? 0) + UIntMax(data.length)
            self.privateModificationTracker = CFAbsoluteTimeGetCurrent()
        })
    }

    /// Empty this log file. Future writes will start from the the beginning of the file.
    func reset() {
        dispatch_sync(self.lockQueue, {
            self.handle.synchronizeFile()
            self.handle.truncateFileAtOffset(0)
            self.privateByteCounter = 0
            self.privateModificationTracker = CFAbsoluteTimeGetCurrent()
        })
    }

}


//MARK: Rotating File Endpoint

/// An Endpoint that writes Log Entries to a set of numbered files. Once a file has reached its maximum file size,
/// the Endpoint automatically rotates to the next file in the set.
///
/// The notifications `LXFileEndpointWillRotateFilesNotification` and `LXFileEndpointDidRotateFilesNotification`
/// are sent to the default notification center directly before and after rotating log files.
public class LXRotatingFileEndpoint: LXEndpoint {

    /// The minimum Priority Level a Log Entry must meet to be accepted by this Endpoint.
    public var minimumPriorityLevel: LXPriorityLevel
    /// The formatter used by this Endpoint to serialize a Log Entry’s `dateTime` property to a string.
    public var dateFormatter: LXDateFormatter
    /// The formatter used by this Endpoint to serialize each Log Entry to a string.
    public var entryFormatter: LXEntryFormatter
    /// This Endpoint requires a newline character appended to each serialized Log Entry string.
    public let requiresNewlines: Bool = true

    /// The URL of the directory in which the set of log files is located.
    public let directoryURL: NSURL
    /// The base file name of the log files.
    private let baseFileName: String
    /// The maximum allowed file size in bytes. `nil` indicates no limit.
    private let maxFileSizeBytes: UIntMax?
    /// The number of files to include in the rotating set.
    private let numberOfFiles: UInt
    /// The index of the current file from the rotating set.
    private lazy var currentIndex: UInt = {
        /* The goal here is to find the file in the set that was last modified (has the largest `modified` time
        interval). If no file returns a `modified` property, it's probably because no files in this set exist yet,
        in which case we'll just return index 1. */
        let startingFile: (index: UInt, modified: NSTimeInterval) = Array(1...self.numberOfFiles).reduce((index: 1, modified: 0), combine: { lastModified, targetIndex in
            if let path = self.URLForIndex(targetIndex).path {
                do {
                    let props = try NSFileManager.defaultManager().propertiesOfFileAtPath(path)
                    if let modified = props.modified where modified >= lastModified.modified {
                        return (index: targetIndex, modified: modified)
                    }
                } catch {/* No props for this file - probably doesn't exist - so just move on */}
            }
            return lastModified
        })
        return startingFile.index
    }()
    /// The file currently being written to.
    private lazy var currentFile: LXLogFile? = {
        guard let file = try? LXLogFile(URL: self.currentURL, shouldAppend: true) else {
            assertionFailure("Could not open the log file at URL '\(self.currentURL.absoluteString)'")
            return nil
        }
        #if !os(watchOS)
        setxattr(file.path, self.extendedAttributeKey, LK_LOGKIT_VERSION, LK_LOGKIT_VERSION.utf8.count, 0, 0)
        #endif
        return file
    }()

    /// Initialize a Rotating File Endpoint.
    ///
    /// If the specified file cannot be opened, or if the index-prepended URL evaluates to `nil`, the initializer may
    /// fail.
    ///
    /// - parameter              baseURL: The URL used to build the rotating file set’s file URLs. Each file's index
    ///                                   number will be prepended to the last path component of this URL. Defaults
    ///                                   to `Application Support/{bundleID}/logs/{number}_log.txt`. Must not be `nil`.
    /// - parameter        numberOfFiles: The number of files to be used in the rotation. Defaults to `5`.
    /// - parameter       maxFileSizeKiB: The maximum file size of each file in the rotation, specified in kilobytes.
    ///                                   Passing `nil` results in no limit, and no automatic rotation. Defaults
    ///                                   to `1024`.
    /// - parameter minimumPriorityLevel: The minimum Priority Level a Log Entry must meet to be accepted by this
    ///                                   Endpoint. Defaults to `.All`.
    /// - parameter        dateFormatter: The formatter used by this Endpoint to serialize a Log Entry’s `dateTime`
    ///                                   property to a string. Defaults to `.standardFormatter()`.
    /// - parameter       entryFormatter: The formatter used by this Endpoint to serialize each Log Entry to a string.
    ///                                   Defaults to `.standardFormatter()`.
    public init?(
        baseURL: NSURL? = defaultLogFileURL,
        numberOfFiles: UInt = 5,
        maxFileSizeKiB: UInt? = 1024,
        minimumPriorityLevel: LXPriorityLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        self.dateFormatter = dateFormatter
        self.entryFormatter = entryFormatter
        self.maxFileSizeBytes = maxFileSizeKiB == nil ? nil : UIntMax(maxFileSizeKiB!) * 1024
        self.numberOfFiles = numberOfFiles
        //TODO: check file or directory to predict if file is accessible
        guard let dirURL = baseURL?.URLByDeletingLastPathComponent, filename = baseURL?.lastPathComponent else {
            assertionFailure("The log file URL '\(baseURL?.absoluteString ?? String())' is invalid")
            self.minimumPriorityLevel = .None
            self.directoryURL = NSURL(string: "")!
            self.baseFileName = ""
            return nil
        }
        self.minimumPriorityLevel = minimumPriorityLevel
        self.directoryURL = dirURL
        self.baseFileName = filename
    }

    /// The name of the extended attribute metadata item used to identify one of this Endpoint's files.
    private var extendedAttributeKey: String { return "info.logkit.endpoint.rotatingFile" }
    /// The index of the next file in the rotation.
    private var nextIndex: UInt { return self.currentIndex + 1 > self.numberOfFiles ? 1 : self.currentIndex + 1 }
    /// The URL of the log file currently in use. Manually modifying this file is _not_ recommended.
    public var currentURL: NSURL { return self.URLForIndex(self.currentIndex) }
    /// The URL of the next file in the rotation.
    private var nextURL: NSURL { return self.URLForIndex(self.nextIndex) }

    /// The URL for the file at a given index.
    private func URLForIndex(index: UInt) -> NSURL {
        return self.directoryURL.URLByAppendingPathComponent(self.fileNameForIndex(index), isDirectory: false)
    }

    /// The name for the file at a given index.
    private func fileNameForIndex(index: UInt) -> String {
        let format = "%0\(Int(floor(log10(Double(self.numberOfFiles)) + 1.0)))d"
        return "\(String(format: format, index))_\(self.baseFileName)"
    }

    /// Returns the next log file to be written to, already prepared for use.
    private func nextFile() -> LXLogFile? {
        guard let nextFile = try? LXLogFile(URL: self.nextURL, shouldAppend: false) else {
            assertionFailure("The log file at URL '\(self.nextURL)' could not be opened.")
            return nil
        }
        #if !os(watchOS)
        setxattr(nextFile.path, self.extendedAttributeKey, LK_LOGKIT_VERSION, LK_LOGKIT_VERSION.utf8.count, 0, 0)
        #endif
        return nextFile
    }

    /// Writes a serialized Log Entry string to the currently selected file.
    public func write(string: String) {
        if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
            //TODO: might pass test but file fills before write
            if self.shouldRotateBeforeWritingDataWithLength(data.length), let nextFile = self.nextFile() {
                self.rotateToFile(nextFile)
            }
            self.currentFile?.writeData(data)
        } else {
            assertionFailure("Failure to create data from entry string")
        }
    }

    /// Clears the currently selected file and begins writing again at its beginning.
    public func resetCurrentFile() {
        self.currentFile?.reset()
    }

    /// Instructs the Endpoint to rotate to the next log file in its sequence.
    public func rotate() {
        if let nextFile = self.nextFile() {
            self.rotateToFile(nextFile)
        }
    }

    /// Sets the current file to the next index and notifies about rotation
    private func rotateToFile(nextFile: LXLogFile) {
        //TODO: Move these notifications into property observers, if the properties can be made non-lazy.
        //TODO: Getting `nextURL` from `nextFile`, instead of calculating it again, might be more robust.
        NSNotificationCenter.defaultCenter().postNotificationName(
            LXFileEndpointWillRotateFilesNotification,
            object: self,
            userInfo: [
                LXFileEndpointRotationCurrentURLKey: self.currentURL,
                LXFileEndpointRotationNextURLKey: self.nextURL
            ]
        )

        let previousURL = self.currentURL
        self.currentFile = nextFile
        self.currentIndex = self.nextIndex

        NSNotificationCenter.defaultCenter().postNotificationName(
            LXFileEndpointDidRotateFilesNotification,
            object: self,
            userInfo: [
                LXFileEndpointRotationCurrentURLKey: self.currentURL,
                LXFileEndpointRotationPreviousURLKey: previousURL
            ]
        )
    }

    /// This method provides an opportunity to determine whether a new log file should be selected before writing the
    /// next Log Entry.
    ///
    /// - parameter length: The length of the data (number of bytes) that will be written next.
    ///
    /// - returns: A boolean indicating whether a new log file should be selected.
    private func shouldRotateBeforeWritingDataWithLength(length: Int) -> Bool {
        switch (self.maxFileSizeBytes, self.currentFile?.sizeInBytes) {
        case (.Some(let maxSize), .Some(let size)) where size + UIntMax(length) > maxSize: // Won't fit
            fallthrough
        case (.Some, .None):                                                               // Can't determine current size
            return true
        case (.None, .None), (.None, .Some), (.Some, .Some):                               // No limit or will fit
            return false
        }
    }

}


//MARK: File Endpoint

/// An Endpoint that writes Log Entries to a specified file.
public class LXFileEndpoint: LXRotatingFileEndpoint {

    /// Initialize a File Endpoint.
    ///
    /// If the specified file cannot be opened, or if the URL evaluates to `nil`, the initializer may fail.
    ///
    /// - parameter              fileURL: The URL of the log file.
    ///                                   Defaults to `Application Support/{bundleID}/logs/log.txt`. Must not be `nil`.
    /// - parameter         shouldAppend: Indicates whether the Endpoint should continue appending Log Entries to the
    ///                                   end of the file, or clear it and start at the beginning. Defaults to `true`.
    /// - parameter minimumPriorityLevel: The minimum Priority Level a Log Entry must meet to be accepted by this
    ///                                   Endpoint. Defaults to `.All`.
    /// - parameter        dateFormatter: The formatter used by this Endpoint to serialize a Log Entry’s `dateTime`
    ///                                   property to a string. Defaults to `.standardFormatter()`.
    /// - parameter       entryFormatter: The formatter used by this Endpoint to serialize each Log Entry to a string.
    ///                                   Defaults to `.standardFormatter()`.
    public init?(
        fileURL: NSURL? = defaultLogFileURL,
        shouldAppend: Bool = true,
        minimumPriorityLevel: LXPriorityLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        super.init(
            baseURL: fileURL,
            numberOfFiles: 1,
            maxFileSizeKiB: nil,
            minimumPriorityLevel: minimumPriorityLevel,
            dateFormatter: dateFormatter,
            entryFormatter: entryFormatter
        )
        if !shouldAppend {
            self.resetCurrentFile()
        }
    }

    /// The name of the extended attribute metadata item used to identify one of this Endpoint's files.
    private override var extendedAttributeKey: String { return "info.logkit.endpoint.file" }

    /// This Endpoint always uses `baseFileName` as its file name.
    private override func fileNameForIndex(index: UInt) -> String {
        return self.baseFileName
    }

    /// Does nothing. File Endpoint does not rotate.
    public override func rotate() {}

    /// This endpoint will never rotate files.
    private override func shouldRotateBeforeWritingDataWithLength(length: Int) -> Bool {
        return false
    }

}


//MARK: Dated File Endpoint

/// An Endpoint that writes Log Enties to a dated file. A datestamp will be prepended to the file's name. The file
/// rotates automatically at midnight UTC.
///
/// The notifications `LXFileEndpointWillRotateFilesNotification` and `LXFileEndpointDidRotateFilesNotification` are
/// sent to the default notification center directly before and after rotating log files.
public class LXDatedFileEndpoint: LXRotatingFileEndpoint {

    /// The formatter used for datestamp preparation.
    private let nameFormatter = LXDateFormatter.dateOnlyFormatter()

    /// Initialize a Dated File Endpoint.
    ///
    /// If the specified file cannot be opened, or if the datestamp-prepended URL evaluates to `nil`, the initializer
    /// may fail.
    ///
    /// - parameter              baseURL: The URL used to build the date files’ URLs. Today's date will be prepended
    ///                                   to the last path component of this URL. Must not be `nil`.
    ///                                   Defaults to `Application Support/{bundleID}/logs/{datestamp}_log.txt`.
    /// - parameter minimumPriorityLevel: The minimum Priority Level a Log Entry must meet to be accepted by this
    ///                                   Endpoint. Defaults to `.All`.
    /// - parameter        dateFormatter: The formatter used by this Endpoint to serialize a Log Entry’s `dateTime`
    ///                                   property to a string. Defaults to `.standardFormatter()`.
    /// - parameter       entryFormatter: The formatter used by this Endpoint to serialize each Log Entry to a string.
    ///                                   Defaults to `.standardFormatter()`.
    public init?(
        baseURL: NSURL? = defaultLogFileURL,
        minimumPriorityLevel: LXPriorityLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        super.init(
            baseURL: baseURL,
            numberOfFiles: 1,
            maxFileSizeKiB: nil,
            minimumPriorityLevel: minimumPriorityLevel,
            dateFormatter: dateFormatter,
            entryFormatter: entryFormatter
        )
    }

    /// The name of the extended attribute metadata item used to identify one of this Endpoint's files.
    private override var extendedAttributeKey: String { return "info.logkit.endpoint.datedFile" }

    /// The name for the file with today's date.
    private override func fileNameForIndex(index: UInt) -> String {
        return "\(self.nameFormatter.stringFromDate(NSDate()))_\(self.baseFileName)"
    }

    /// Does nothing. Dated File Endpoint only rotates by date.
    public override func rotate() {}

    /// Returns `true` if the current date no longer matches the log file's date. Disregards the `length` parameter.
    private override func shouldRotateBeforeWritingDataWithLength(length: Int) -> Bool {
        switch self.currentFile?.modificationDate {
        case .Some(let modificationDate) where !UTCCalendar.isDateSameAsToday(modificationDate):    // Wrong date
            fallthrough
        case .None:                                                                                 // Can't determine the date
            return true
        case .Some:                                                                                 // Correct date
            return false
        }
    }

    //TODO: Cap the max number trailing log files.

}
