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


private let defaultLogFileURL: NSURL? = LK_DEFAULT_LOG_DIRECTORY?.URLByAppendingPathComponent("log.txt", isDirectory: false)
private let UTCCalendar: NSCalendar = { //TODO: this is a cheap hack because .currentCalendar() compares dates based on local TZ
    let cal = NSCalendar.currentCalendar().copy() as! NSCalendar
    cal.timeZone = NSTimeZone(forSecondsFromGMT: 0)
    return cal
}()


private extension NSFileManager {

    private func propertiesOfFileAtPath(path: String) throws -> LXFileProperties {
        let attributes = try NSFileManager.defaultManager().attributesOfItemAtPath(path)
        return LXFileProperties(
            size: (attributes[NSFileSize] as? NSNumber)?.unsignedLongLongValue,
            modified: (attributes[NSFileModificationDate] as? NSDate)?.timeIntervalSinceReferenceDate
        )
    }

}


private struct LXFileProperties {
    let size: UIntMax?
    let modified: NSTimeInterval?
}


private class LXLogFile {

    private let lockQueue: dispatch_queue_t = dispatch_queue_create("logFile-Lock", DISPATCH_QUEUE_SERIAL)
    private let handle: NSFileHandle
    private let path: String
    private var privateByteCounter: UIntMax?
    private var privateModificationTracker: NSTimeInterval?

    init?(URL: NSURL, shouldAppend: Bool) {
        guard NSFileManager.defaultManager().ensureFileAtURL(URL, withIntermediateDirectories: true),
        let path = URL.path, handle = NSFileHandle(forWritingAtPath: path) else {
            assertionFailure("Error opening log file at URL '\(URL.absoluteString)'; is URL valid?")
            self.path = ""
            self.handle = NSFileHandle.fileHandleWithNullDevice()
            self.handle.closeFile()
            return nil
        }
        self.path = path
        self.handle = handle
        if shouldAppend {
            self.privateByteCounter = UIntMax(self.handle.seekToEndOfFile())
        } else {
            self.handle.truncateFileAtOffset(0)
            self.privateByteCounter = 0
        }
        do {
            try self.privateModificationTracker = NSFileManager.defaultManager().propertiesOfFileAtPath(path).modified
        } catch {}
    }

    deinit {
        dispatch_sync(self.lockQueue, {
            self.handle.synchronizeFile()
            self.handle.closeFile()
        })
    }

    var sizeInBytes: UIntMax? {
        var size: UIntMax?
        dispatch_sync(self.lockQueue, { size = self.privateByteCounter })
        return size
    }

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

    func writeData(data: NSData) {
        dispatch_async(self.lockQueue, {
            self.handle.writeData(data)
            self.privateByteCounter = (self.privateByteCounter ?? 0) + UIntMax(data.length)
            self.privateModificationTracker = CFAbsoluteTimeGetCurrent()
        })
    }

    func reset() {
        dispatch_sync(self.lockQueue, {
            self.handle.synchronizeFile()
            self.handle.truncateFileAtOffset(0)
            self.privateByteCounter = 0
            self.privateModificationTracker = CFAbsoluteTimeGetCurrent()
        })
    }

}


public class LXRotatingFileEndpoint: LXEndpoint {
    public var minimumLogLevel: LXLogLevel
    public var dateFormatter: LXDateFormatter
    public var entryFormatter: LXEntryFormatter
    public let requiresNewlines: Bool = true

    private let directoryURL: NSURL
    private let baseFileName: String
    private let maxFileSizeBytes: UIntMax
    private let numberOfFiles: UInt

    private lazy var currentIndex: UInt = {
        let startingFile: (index: UInt, modified: NSTimeInterval) = Array(1...self.numberOfFiles).reduce((1, 0), combine: {
            if let path = self.URLForIndex($1).path {
                do {
                    let props = try NSFileManager.defaultManager().propertiesOfFileAtPath(path)
                    if let modified = props.modified where modified > $0.1 {
                        return (index: $1, modified: modified)
                    }
                } catch {}
            }
            return $0
        })
        return startingFile.index
    }()

    private lazy var currentFile: LXLogFile? = {
        print("Selected: \(self.currentIndex)")
        guard let file = LXLogFile(URL: self.currentURL, shouldAppend: true) else {
            assertionFailure("Could not open the log file at URL '\(self.currentURL.absoluteString)'")
            return nil
        }
        return file
    }()

    public init?(
        baseURL: NSURL? = defaultLogFileURL,
        numberOfFiles: UInt = 5,
        maxFileSizeKiB: UInt = 1024,
        minimumLogLevel: LXLogLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        self.dateFormatter = dateFormatter
        self.entryFormatter = entryFormatter
        self.maxFileSizeBytes = UIntMax(maxFileSizeKiB) * 1024
        self.numberOfFiles = numberOfFiles
        //TODO: check file or directory to predict if file is accessible
        guard let dirURL = baseURL?.URLByDeletingLastPathComponent, filename = baseURL?.lastPathComponent else {
            assertionFailure("The log file URL '\(baseURL?.absoluteString ?? String())' is invalid")
            self.minimumLogLevel = .None
            self.directoryURL = NSURL(string: "")!
            self.baseFileName = ""
            return nil
        }
        self.minimumLogLevel = minimumLogLevel
        self.directoryURL = dirURL
        self.baseFileName = filename
    }

    private var nextIndex: UInt { return self.currentIndex + 1 > self.numberOfFiles ? 1 : self.currentIndex + 1 }
    private var currentURL: NSURL { return self.URLForIndex(self.currentIndex) }
    private var nextURL: NSURL { return self.URLForIndex(self.nextIndex) }

    private func URLForIndex(index: UInt) -> NSURL {
        return self.directoryURL.URLByAppendingPathComponent(self.fileNameForIndex(index), isDirectory: false)
    }

    private func fileNameForIndex(index: UInt) -> String {
        let format = "%0\(Int(floor(log10(Double(self.numberOfFiles)) + 1.0)))d"
        return "\(String(format: format, index))_\(self.baseFileName)"
    }

    public func write(string: String) {
        if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
            //TODO: might pass test but file fills before write
            if let nextFile = self.rotateToFileBeforeWritingDataWithLength(data.length) {
                self.currentFile = nextFile
                self.currentIndex = self.nextIndex
            }
            self.currentFile?.writeData(data)
            print("Wrote to \(self.currentIndex); total \(self.currentFile?.sizeInBytes ?? 0) bytes")
        } else {
            assertionFailure("Failure to create data from entry string")
        }
    }

    public func resetCurrentFile() {
        self.currentFile?.reset()
    }

    private func rotateToFileBeforeWritingDataWithLength(length: Int) -> LXLogFile? {
        switch self.currentFile?.sizeInBytes {
        case .Some(let size) where size + UIntMax(length) > self.maxFileSizeBytes:  // Won't fit in current file
            fallthrough
        case .None:                                                                 // Can't determine size of current file
            return LXLogFile(URL: self.nextURL, shouldAppend: false)
        case .Some:                                                                 // Will fit in current file
            return nil
        }
    }

}


public class LXFileEndpoint: LXRotatingFileEndpoint {

    public init?(
        fileURL: NSURL? = defaultLogFileURL,
        shouldAppend: Bool = true,
        minimumLogLevel: LXLogLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        super.init(
            baseURL: fileURL,
            numberOfFiles: 1,
            maxFileSizeKiB: 0,
            minimumLogLevel: minimumLogLevel,
            dateFormatter: dateFormatter,
            entryFormatter: entryFormatter
        )
    }

    private override func fileNameForIndex(index: UInt) -> String {
        return self.baseFileName
    }

    private override func rotateToFileBeforeWritingDataWithLength(length: Int) -> LXLogFile? {
        return nil
    }
    
}


public class LXDatedFileEndpoint: LXRotatingFileEndpoint {

    private let nameFormatter = LXDateFormatter.dateOnlyFormatter()

    public init?(
        baseURL: NSURL? = defaultLogFileURL,
        minimumLogLevel: LXLogLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        super.init(
            baseURL: baseURL,
            numberOfFiles: 1,
            maxFileSizeKiB: 0,
            minimumLogLevel: minimumLogLevel,
            dateFormatter: dateFormatter,
            entryFormatter: entryFormatter
        )
    }

    private override func fileNameForIndex(index: UInt) -> String {
        return "\(self.nameFormatter.stringFromDate(NSDate()))_\(self.baseFileName)"
    }

    private override func rotateToFileBeforeWritingDataWithLength(length: Int) -> LXLogFile? {
        switch self.currentFile?.modificationDate {
        case .Some(let modificationDate) where !UTCCalendar.isDateSameAsToday(modificationDate):    // Wrong date
            fallthrough
        case .None:                                                                                 // Don't know
            return LXLogFile(URL: self.nextURL, shouldAppend: false)
        case .Some:                                                                                 // Correct date
            return nil
        }
    }

}
