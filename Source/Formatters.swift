// Formatters.swift
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


public class LXDateFormatter {
    public class func standardFormatter() -> Self { return self.init(formatString: "yyyy-MM-dd HH:mm:ss.SSS") }
    public class func timeOnlyFormatter() -> Self { return self.init(formatString: "HH:mm:ss.SSS") }
    public class func dateOnlyFormatter() -> Self { return self.init(formatString: "yyyy-MM-dd") }

    private let dateFormatter: NSDateFormatter

    public required init(formatString: String, timeZone: NSTimeZone = NSTimeZone(forSecondsFromGMT: 0)) {
        self.dateFormatter = NSDateFormatter()
        self.dateFormatter.timeZone = timeZone
        self.dateFormatter.dateFormat = formatString
    }

    internal func stringFromDate(date: NSDate) -> String {
        return self.dateFormatter.stringFromDate(date)
    }

}


public class LXEntryFormatter {

    public class func standardFormatter() -> Self { return self.init(closure: { entry in
        return "\(entry.dateTime) [\(entry.logLevel.uppercaseString)] \(entry.functionName) <\(entry.fileName):\(entry.lineNumber)> \(entry.message)"
    })}
    public class func shortFormatter() -> Self { return self.init(closure: { entry in
        return "\(entry.dateTime) [\(entry.logLevel.uppercaseString)] \(entry.message)"
    })}
    public class func longFormatter() -> Self { return self.init(closure: { entry in
        return "\(entry.dateTime) (\(entry.timestamp)) [\(entry.logLevel.uppercaseString)] {thread: \(entry.threadID) '\(entry.threadName)' main: \(entry.isMainThread)} \(entry.functionName) <\(entry.fileName):\(entry.lineNumber).\(entry.columnNumber)> \(entry.message)"
    })}
    public class func messageOnlyFormatter() -> Self { return self.init(closure: { entry in return entry.message }) }

    private let entryFormatter: (entry: LXLogEntry) -> String

    public required init(closure: (LXLogEntry) -> String) {
        self.entryFormatter = closure
    }

    internal func stringFromEntry(entry: LXLogEntry, appendNewline: Bool) -> String {
        return appendNewline ? entryFormatter(entry: entry) + "\n" : entryFormatter(entry: entry)
    }

}


extension LXEntryFormatter {
    private enum EntryFormattingError: ErrorType { case DecodingError }

    public class func jsonFormatter() -> Self { return self.init(closure: { entry in
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(entry.asMap(), options: [])
            guard let json = NSString(data: data, encoding: NSUTF8StringEncoding) else {
                throw EntryFormattingError.DecodingError
            }
            return json as String
        } catch {
            assertionFailure("Log entry could not be serialized to JSON")
            return "{\"error\": \"serialization_error\"}"
        }
    })}

}
