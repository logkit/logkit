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
#elseif os(watchOS)
import WatchKit
#endif

/* This file is admittedly somewhat of a dumping ground for globals. */


//MARK: Global Constants

/// The version of the LogKit framework currently in use.
internal let LK_LOGKIT_VERSION = "2.0.0"


/// The default queue used throughout the framework for background tasks.
internal let LK_LOGKIT_QUEUE: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)


/// The default log file directory; `Application Support/{bundleID}/logs/`.
internal let LK_DEFAULT_LOG_DIRECTORY: NSURL? = {
    if let appSupportURL = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask).first {
        let bundleID = NSBundle.mainBundle().bundleIdentifier ?? "info.logkit.LogKit"
        return appSupportURL.URLByAppendingPathComponent(bundleID, isDirectory: true).URLByAppendingPathComponent("logs", isDirectory: true)
    } else {
        assertionFailure("Unable to build default log file URL from main bundle ID and Application Support directory")
        return nil
    }
}()


/// The bundle ID of the currently running host application, _not_ the LogKit framework.
internal let LK_BUNDLE_ID: String = NSBundle.mainBundle().bundleIdentifier ?? ""


/// The model of this device.
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


/// The type of this device.
internal let LK_DEVICE_TYPE: String = {
#if os(OSX)
    return "Mac"
#elseif os(iOS)
    return UIDevice.currentDevice().model
#elseif os(watchOS)
    return WKInterfaceDevice.currentDevice().model
#else
    return ""
#endif
}()


/// A tuple describing OS this device is running.
internal let LK_DEVICE_OS: (decription: String, majorVersion: Int, minorVersion: Int, patchVersion: Int, buildVersion: String) = {
    let systemVersion = NSDictionary(contentsOfFile: "/System/Library/CoreServices/SystemVersion.plist")
    let build = systemVersion?["ProductBuildVersion"] as? String ?? ""
    let info = NSProcessInfo.processInfo()
    let description = info.operatingSystemVersionString
#if os(OSX) // Ugly hack, see issue #7
    if #available(OSX 10.10, OSXApplicationExtension 10.10, *) {
        let version = info.operatingSystemVersion
        return (description, version.majorVersion, version.minorVersion, version.patchVersion, build)
    } else {
        let version = systemVersion?["ProductVersion"] as? String
        let parts = version?.characters.split(".") ?? []
        let major = parts.count > 0 ? Int(String(parts[0])) ?? -1 : -1
        let minor = parts.count > 1 ? Int(String(parts[1])) ?? -1 : -1
        let patch = parts.count > 2 ? Int(String(parts[2])) ?? -1 : -1
        return (description, major, minor, patch, build)
    }
#else
    if info.respondsToSelector("operatingSystemVersion") {
        let version = info.operatingSystemVersion
        return (description, version.majorVersion, version.minorVersion, version.patchVersion, build)
    } else {
        let version = systemVersion?["ProductVersion"] as? String
        let parts = version?.characters.split(".") ?? []
        let major = parts.count > 0 ? Int(String(parts[0])) ?? -1 : -1
        let minor = parts.count > 1 ? Int(String(parts[1])) ?? -1 : -1
        let patch = parts.count > 2 ? Int(String(parts[2])) ?? -1 : -1
        return (description, major, minor, patch, build)
    }
#endif
}()


/**
A tuple of any device IDs available.

In OS X, only the `vendor` ID is available.

In iOS, the `advertising` ID honors the `advertisingTrackingEnabled` flag, and is only returned if that flag is true.

Other OSes currently return empty strings.
*/
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


//MARK: Shared Extensions

internal extension NSFileManager {

    /**
    This method attempts to ensure that a file is available at the specified URL. It will attempt to create an empty file if
    one does not already exist at that location.
    
    - parameter withIntermediateDirectories: Indicates whether intermediate directories should be created if necessary, before
    checking for the file.
    
    - returns: A `Bool` indicating whether the file is available or not.
    */
    internal func ensureFileAtURL(URL: NSURL, withIntermediateDirectories shouldCreateDirs: Bool) -> Bool {
        if let dirURL = URL.URLByDeletingLastPathComponent, path = URL.path {
            do {
                let manager = NSFileManager.defaultManager()
                try manager.createDirectoryAtURL(dirURL, withIntermediateDirectories: shouldCreateDirs, attributes: nil)
                return manager.fileExistsAtPath(path) ? true : manager.createFileAtPath(path, contents: nil, attributes: nil)
            } catch {
                assertionFailure("File system error (maybe access denied) at path: '\(path)'")
            }
        }
        assertionFailure("Invalid file path '\(URL.absoluteString)'")
        return false
    }

}


internal extension NSCalendar {

    /// Returns whether the given date is the same date as "today". Exists as a compatibility shim for older operating systems.
    internal func isDateSameAsToday(date: NSDate) -> Bool {
        if self.respondsToSelector("isDateInToday:") {
            return self.isDateInToday(date)
        } else {
            let today = NSDate()
            let todayDay = self.ordinalityOfUnit(.Day, inUnit: .Year, forDate: today)
            let todayYear = self.ordinalityOfUnit(.Year, inUnit: .Era, forDate: today)
            let dateDay = self.ordinalityOfUnit(.Day, inUnit: .Year, forDate: date)
            let dateYear = self.ordinalityOfUnit(.Year, inUnit: .Era, forDate: date)
            return todayYear == dateYear && todayDay == dateDay
        }
    }

}
