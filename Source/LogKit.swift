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
internal let logKitVersion = "2.0.0-beta-1"


internal let defaultQueue: dispatch_queue_t = {
    if #available(OSX 10.10, OSXApplicationExtension 10.10,  iOS 8.0, iOSApplicationExtension 8.0, watchOS 2.0, *) {
        return dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
    } else {
        return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    }
}()


internal let defaultLogFileURL: NSURL? = {
    guard let
        bundleID = NSBundle.mainBundle().bundleIdentifier,
        appSupportURL = NSFileManager.defaultManager()
            .URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask).first
    else {
        assertionFailure("Unable to build default log file URL from main bundle ID and Application Support directory")
        return nil
    }
    return appSupportURL
        .URLByAppendingPathComponent(bundleID, isDirectory: true)
        .URLByAppendingPathComponent("logs", isDirectory: true)
        .URLByAppendingPathComponent("log.txt", isDirectory: false)
}()


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


internal extension String {
    /// Returns a dispatch_data_t object containing a representation of the String encoded using a given encoding.
    func dispatchDataUsingEncoding(encoding: NSStringEncoding) -> dispatch_data_t? {
        if let nData = self.dataUsingEncoding(encoding), dData = dispatch_data_create(nData.bytes, nData.length, nil, nil) {
            return dData
        } else {
            return nil
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


internal func dispatchRepeatingTimer(
    delay delay: NSTimeInterval,
    interval: NSTimeInterval,
    tolerance: NSTimeInterval,
    handler: () -> Void
) -> dispatch_source_t {
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
