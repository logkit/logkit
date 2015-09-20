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
#if os(iOS)
import UIKit
import AdSupport
#endif

/* This file is admittedly somewhat of a dumping ground for globals. */


/// The version of the LogKit framework currently in use.
internal let LK_LOGKIT_VERSION = "2.0.0-beta-1"


internal let LK_LOGKIT_QUEUE: dispatch_queue_t = {
    if #available(OSX 10.10, OSXApplicationExtension 10.10,  iOS 8.0, iOSApplicationExtension 8.0, watchOS 2.0, *) {
        return dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
    } else {
        return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    }
}()


internal let LK_LOG_FILE_URL: NSURL? = {
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


internal extension NSFileManager {

    internal func ensureFileAtURL(URL: NSURL, withIntermediateDirectories createDirs: Bool) -> Bool {
        if let dirURL = URL.URLByDeletingLastPathComponent, path = URL.path {
            do {
                let manager = NSFileManager.defaultManager()
                try manager.createDirectoryAtURL(dirURL, withIntermediateDirectories: createDirs, attributes: nil)
                return manager.fileExistsAtPath(path) ? true : manager.createFileAtPath(path, contents: nil, attributes: nil)
            } catch {
                assertionFailure("File system error (maybe access denied) at path: '\(path)'")
            }
        }
        assertionFailure("Invalid file path '\(URL.absoluteString)'")
        return false
    }
    
}


internal func dispatchRepeatingTimer(
    delay delay: NSTimeInterval,
    interval: NSTimeInterval,
    tolerance: NSTimeInterval,
    handler: () -> Void
) -> dispatch_source_t {
    let DOUBLE_NANO_PER_SEC = Double(NSEC_PER_SEC)
    let timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, LK_LOGKIT_QUEUE)
    dispatch_source_set_event_handler(timer, handler)
    dispatch_source_set_timer(
        timer,
        dispatch_time(DISPATCH_TIME_NOW, Int64(delay * DOUBLE_NANO_PER_SEC)),
        UInt64(interval * DOUBLE_NANO_PER_SEC),
        UInt64(tolerance * DOUBLE_NANO_PER_SEC)
    )
    return timer
}


internal let LK_BUNDLE_ID: String = NSBundle.mainBundle().bundleIdentifier ?? ""

internal let LK_DEVICE_MODEL: String = {
    var len: size_t = 0
    if sysctlbyname("hw.model", nil, &len, nil, 0) == 0 {
        var result = Array<CChar>(count: len, repeatedValue: 0)
        if sysctlbyname("hw.model", &result, &len, nil, 0) == 0 {
            return String.fromCString(result) ?? ""
        }
    }
    return ""
}()

internal let LK_DEVICE_OS: (decription: String, majorVersion: Int, minorVersion: Int, patchVersion: Int, buildVersion: String) = {
    var hold: (String, Int, Int, Int, String)?
    dispatch_sync(LK_LOGKIT_QUEUE, {
        let systemVersion = NSDictionary(contentsOfFile: "/System/Library/CoreServices/SystemVersion.plist")
        let build = systemVersion?["ProductBuildVersion"] as? String ?? ""
        let info = NSProcessInfo.processInfo()
        let description = info.operatingSystemVersionString
        if #available(OSX 10.10, OSXApplicationExtension 10.10,  iOS 8.0, iOSApplicationExtension 8.0, watchOS 2.0, *) {
            let version = info.operatingSystemVersion
            hold = (description, version.majorVersion, version.minorVersion, version.patchVersion, build)
        } else {
            let version = systemVersion?["ProductVersion"] as? String
            let parts = version?.characters.split(".") ?? []
            let major = parts.count > 0 ? Int(String(parts[0])) ?? -1 : -1
            let minor = parts.count > 1 ? Int(String(parts[1])) ?? -1 : -1
            let patch = parts.count > 2 ? Int(String(parts[2])) ?? -1 : -1
            hold = (description, major, minor, patch, build)
        }
    })
    return hold!
}()


internal let LK_DEVICE_IDS: (vendor: String, advertising: String) = {
#if os(OSX)
    var timeSpec = timespec(tv_sec: 0, tv_nsec: 0)
    var bytes = Array<CUnsignedChar>(count: 16, repeatedValue: 0)
    guard gethostuuid(&bytes, &timeSpec) == 0 else {
        return ("", "")
    }
    let nsuuid = NSUUID(UUIDBytes: bytes)
    return (nsuuid.UUIDString, "")
#elseif os(iOS)
    let vendorID = UIDevice.currentDevice().identifierForVendor?.UUIDString ?? ""
    let adManager = ASIdentifierManager.sharedManager()
    let advertisingID = adManager.advertisingTrackingEnabled ? adManager.advertisingIdentifier.UUIDString : ""
    return (vendorID, advertisingID)
#else
    return ("", "")
#endif
}()
