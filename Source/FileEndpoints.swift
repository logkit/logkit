// FileEndpoints.swift
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


internal extension NSCalendar {

    internal func isDateNotToday(date: NSDate) -> Bool {
        if #available(iOS 8.0, iOSApplicationExtension 8.0, watchOS 2.0, *) {
            return !self.isDate(date, inSameDayAsDate: NSDate())
        } else {
            let now = NSDate()
            let todayDay = self.ordinalityOfUnit(.Day, inUnit: .Year, forDate: now)
            let todayYear = self.ordinalityOfUnit(.Year, inUnit: .Era, forDate: now)
            let dateDay = self.ordinalityOfUnit(.Day, inUnit: .Year, forDate: date)
            let dateYear = self.ordinalityOfUnit(.Year, inUnit: .Era, forDate: date)
            return todayDay != dateDay || todayYear != dateYear
        }
    }

}


extension NSDate: Comparable {}

public func <(lhs: NSDate, rhs: NSDate) -> Bool {
    switch lhs.compare(rhs) {
    case .OrderedSame, .OrderedDescending:
        return false
    case .OrderedAscending:
        return true
    }
}


private func defaultLogFileURL() -> NSURL? {
    guard let
        bundleID = NSBundle.mainBundle().bundleIdentifier,
        appSupportURL = NSFileManager.defaultManager()
            .URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask).first
    else {
        // TODO: assertion
        return nil
    }
    return appSupportURL
        .URLByAppendingPathComponent(bundleID, isDirectory: true)
        .URLByAppendingPathComponent("logs", isDirectory: true)
        .URLByAppendingPathComponent("log.txt", isDirectory: false)
}


internal func dispatchRepeatingTimer(delay delay: NSTimeInterval, interval: NSTimeInterval, tolerance: NSTimeInterval, handler: () -> Void) -> dispatch_source_t {
    let DOUBLE_NANO_PER_SEC = Double(NSEC_PER_SEC)
    let timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, defaultQueue)
    dispatch_source_set_event_handler(timer, handler)
    dispatch_source_set_timer(
        timer,
        dispatch_time(DISPATCH_TIME_NOW, Int64(delay * DOUBLE_NANO_PER_SEC)),
        UInt64(interval * DOUBLE_NANO_PER_SEC),
        UInt64(tolerance * DOUBLE_NANO_PER_SEC)
    )
    return timer
}


public class LXRotatingFileEndpoint: LXEndpoint {
    public var minimumLogLevel: LXLogLevel
    public var dateFormatter: LXDateFormatter
    public var entryFormatter: LXEntryFormatter
    public let requiresNewlines: Bool = true

    private let directoryURL: NSURL
    private let baseFilename: String
    private let maxFileSizeBytes: Int
    private let numberOfFiles: Int
    private lazy var currentIndex: Int = {
        let names = Array(1...self.numberOfFiles).map({ i -> (index: Int, name: String) in
            return (index: i, name: self.fileNameWithIndex(i))
        })
        let props = names.map({ index, name -> (index: Int, name: String, size: Int?, lastModified: NSDate?) in
            let URL = self.directoryURL.URLByAppendingPathComponent(name, isDirectory: false)
            guard let attributes = self.getAttributesForFileAtURL(URL) else {
                return (index: index, name: name, size: nil, lastModified: nil)
            }
            let size = (attributes[NSFileSize] as? NSNumber)?.integerValue
            let modified = attributes[NSFileModificationDate] as? NSDate
            return (index: index, name: name, size: size, lastModified: modified)
        })
        let lastModIndex = props.filter({ $0.lastModified != nil }).maxElement({ $0.lastModified! > $1.lastModified! })?.index
        let underSizeIndexes = props.filter({ $0.size != nil && $0.size! < self.maxFileSizeBytes }).map({ $0.index })
        switch (lastModIndex) {
        // if lastModified exists and it is under size limit
        case .Some(let index) where underSizeIndexes.contains(index):
            return index
        // if lastModified exists but has reached size limit and index is last file
        case .Some(let index) where index == self.numberOfFiles:
            return 1
        // if lastModified exists but has reached size limit
        case .Some(let index):
            return index + 1
        // if lastModified does not exist
        case .None:
            return 1
        }
    }()
    private lazy var channel: dispatch_io_t = {
        let size = self.getSizeOfFileAtURL(self.currentURL)
        let shouldAppend = size == nil || size! < self.maxFileSizeBytes
        guard let openedChannel = self.openChannelAtURL(self.currentURL, forAppending: shouldAppend) else {
            assertionFailure("Could not open file at URL '\(self.currentURL.absoluteString)'")
            let nullHandle = NSFileHandle.fileHandleWithNullDevice()
            defer { nullHandle.closeFile() }
            return dispatch_io_create(DISPATCH_IO_STREAM, nullHandle.fileDescriptor, defaultQueue, { _ in })
        }
        return openedChannel
    }()
    private lazy var timer: dispatch_source_t = {
        dispatchRepeatingTimer(delay: 5.0, interval: 30.0, tolerance: 5.0, handler: { self.rotateIfNeeded() })
    }()

    public init?(
        baseURL: NSURL? = defaultLogFileURL(),
        numberOfFiles: Int = 5,
        maxFileSizeKiB: Int = 1024,
        minimumLogLevel: LXLogLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        do {
            self.dateFormatter = dateFormatter
            self.entryFormatter = entryFormatter
            self.maxFileSizeBytes = maxFileSizeKiB * 1024
            self.numberOfFiles = numberOfFiles
            guard let dirURL = baseURL?.URLByDeletingLastPathComponent, filename = baseURL?.lastPathComponent else {
                throw LXEndpointError.CustomError(message: "The log file URL '\(baseURL?.absoluteString ?? String())' is invalid")
            }
            try NSFileManager.defaultManager().createDirectoryAtURL(dirURL, withIntermediateDirectories: true, attributes: nil)
            self.minimumLogLevel = minimumLogLevel
            self.directoryURL = dirURL
            self.baseFilename = filename
        } catch let error {
            assertionFailure("\(error)")
            self.minimumLogLevel = .None
            self.directoryURL = NSURL(string: "")!
            self.baseFilename = ""
            return nil
        }
        dispatch_resume(self.timer)
    }

    deinit {
        dispatch_source_cancel(self.timer)
        dispatch_io_close(self.channel, 0)
    }

    private var currentURL: NSURL {
        return self.directoryURL.URLByAppendingPathComponent(self.fileNameWithIndex(self.currentIndex), isDirectory: false)
    }

    private var nextIndex: Int {
        return self.currentIndex >= self.numberOfFiles ? 1 : self.currentIndex + 1
    }

    public func write(entryString: String) {
        if let data = entryString.dispatchDataUsingEncoding(NSUTF8StringEncoding) {
            dispatch_io_write(self.channel, 0, data, defaultQueue, { _, _, _ in })
        } else {
            assertionFailure("Failure to create data from entry string")
        }
        dispatch_async(defaultQueue, { self.rotateIfNeeded() })
    }

    private func openChannelAtURL(URL: NSURL, forAppending shouldAppend: Bool) -> dispatch_io_t? {
        guard let path = URL.path else { return nil }
        let appendOption = shouldAppend ? O_APPEND : O_TRUNC
        return dispatch_io_create_with_path(
            DISPATCH_IO_STREAM,
            path,
            O_WRONLY | O_NONBLOCK | appendOption | O_CREAT,
            S_IRUSR | S_IWUSR | S_IRGRP,
            defaultQueue,
            { _ in }
        ) as dispatch_io_t?
    }

    private func URLWithIndex(index: Int) -> NSURL {
        return self.directoryURL.URLByAppendingPathComponent(self.fileNameWithIndex(index), isDirectory: false)
    }

    private func fileNameWithIndex(index: Int) -> String {
        let format = "%0\(Int(floor(log10(Double(self.numberOfFiles)) + 1.0)))d"
        return "\(String(format: format, index))_\(self.baseFilename)"
    }

    private func getAttributesForFileAtURL(URL: NSURL) -> [String: AnyObject]? {
        do {
            guard let filePath = URL.path else {
                throw LXEndpointError.CustomError(message: "Could not determine file '\(URL.absoluteString)' filesystem path")
            }
            return try NSFileManager.defaultManager().attributesOfItemAtPath(filePath)
        } catch {
            return nil
        }
    }

    private func getSizeOfFileAtURL(URL: NSURL) -> Int? {
        return (self.getAttributesForFileAtURL(self.currentURL)?[NSFileSize] as? NSNumber)?.integerValue
    }

    private func shouldRotate() -> Bool {
        guard let currentSize = self.getSizeOfFileAtURL(self.currentURL) else {
            return false //TODO: or should this be true?
        }
        return currentSize >= self.maxFileSizeBytes
    }

    private func doRotate() {
        let nextURL = self.URLWithIndex(self.nextIndex)
        if let newChannel = self.openChannelAtURL(nextURL, forAppending: false) {
            self.currentIndex = self.nextIndex
            let oldChannel = self.channel
            self.channel = newChannel
            dispatch_io_close(oldChannel, 0)
        } else {
            assertionFailure("Failed to open next log file at '\(nextURL.absoluteString)'")
        }
    }

    private func rotateIfNeeded() {
        if self.shouldRotate() {
            self.doRotate()
        }
    }

}


public class LXFileEndpoint: LXRotatingFileEndpoint {

    private override var currentIndex: Int {
        get { return 1 }
        set {}
    }

    public init?(
        fileURL: NSURL? = defaultLogFileURL(),
        shouldAppend: Bool = true,
        minimumLogLevel: LXLogLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        super.init(
            baseURL: fileURL,
            numberOfFiles: 1,
            maxFileSizeKiB: Int.max,
            minimumLogLevel: minimumLogLevel,
            dateFormatter: dateFormatter,
            entryFormatter: entryFormatter
        )
        dispatch_source_cancel(self.timer)
    }

    public override func write(entryString: String) {
        if let data = entryString.dispatchDataUsingEncoding(NSUTF8StringEncoding) {
            dispatch_io_write(self.channel, 0, data, defaultQueue, { _, _, _ in })
        } else {
            assertionFailure("Failure to create data from entry string")
        }
    }

    private override var nextIndex: Int { return 1 }
    private override func fileNameWithIndex(index: Int) -> String { return self.baseFilename }
    private override func shouldRotate() -> Bool { return false }
    private override func doRotate() {}
    private override func rotateIfNeeded() {}

}


public class LXDatedFileEndpoint: LXRotatingFileEndpoint {

    private let nameFormatter = LXDateFormatter.dateOnlyFormatter()

    private override var currentIndex: Int {
        get { return 1 }
        set {}
    }

    public init?(
        baseURL: NSURL? = defaultLogFileURL(),
        minimumLogLevel: LXLogLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        super.init(
            baseURL: baseURL,
            numberOfFiles: 1,
            maxFileSizeKiB: Int.max,
            minimumLogLevel: minimumLogLevel,
            dateFormatter: dateFormatter,
            entryFormatter: entryFormatter
        )
    }

    private override var nextIndex: Int { return 1 }

    private override func fileNameWithIndex(index: Int) -> String {
        return "\(self.nameFormatter.stringFromDate(NSDate()))_\(self.baseFilename)"
    }

    private func getModificationDateOfFileAtURL(URL: NSURL) -> NSDate? {
        return self.getAttributesForFileAtURL(URL)?[NSFileModificationDate] as? NSDate
    }

    private override func shouldRotate() -> Bool {
        guard let modDate = self.getModificationDateOfFileAtURL(self.currentURL) else {
            return false //TODO: or should this be true?
        }
        return NSCalendar.currentCalendar().isDateNotToday(modDate)
    }

}
