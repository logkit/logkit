// LogKit.swift
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
#if os(iOS) || os(tvOS)
import UIKit
import AdSupport
#elseif os(watchOS)
import WatchKit
#endif

/* This file is admittedly somewhat of a dumping ground for globals. */


//MARK: Global Constants

/// The version of the LogKit framework currently in use.
internal let LK_LOGKIT_VERSION = Bundle(identifier: "info.logkit.LogKit")?.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.3.2"


/// The default queue used throughout the framework for background tasks.
internal let LK_LOGKIT_QUEUE: DispatchQueue = {
    if #available(iOS 8.0, OSX 10.10, *) {
        return DispatchQueue.global()
    } else {
        return DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default)
    }
}()


/// The default log file directory; `Application Support/{bundleID}/logs/`.
internal let LK_DEFAULT_LOG_DIRECTORY: URL? = {
    if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
        let bundleID = Bundle.main.bundleIdentifier ?? "info.logkit.LogKit"
        return appSupportURL.appendingPathComponent(bundleID, isDirectory: true).appendingPathComponent("logs", isDirectory: true)
    } else {
        assertionFailure("Unable to build default log file URL from main bundle ID and Application Support directory")
        return nil
    }
}()


/// The bundle ID of the currently running host application, _not_ the LogKit framework.
internal let LK_BUNDLE_ID: String = Bundle.main.bundleIdentifier ?? ""


/// The model of this device.
internal let LK_DEVICE_MODEL: String = {
    var len: size_t = 0
    if sysctlbyname("hw.model", nil, &len, nil, 0) == 0 {
        var result = Array<CChar>(repeating: 0, count: len)
        if sysctlbyname("hw.model", &result, &len, nil, 0) == 0 {
            return String(cString: result)
        }
    }
    return ""
}()


/// The type of this device.
internal let LK_DEVICE_TYPE: String = {
#if os(OSX)
    return "Mac"
#elseif os(iOS) || os(tvOS)
    return UIDevice.current.model
#elseif os(watchOS)
    return WKInterfaceDevice.current().model
#else
    return ""
#endif
}()


/// A tuple describing OS this device is running.
internal let LK_DEVICE_OS: (description: String, majorVersion: Int, minorVersion: Int, patchVersion: Int, buildVersion: String) = {
    let systemVersion = NSDictionary(contentsOfFile: "/System/Library/CoreServices/SystemVersion.plist")
    let build = systemVersion?["ProductBuildVersion"] as? String ?? ""
    let info = ProcessInfo.processInfo
    let description = info.operatingSystemVersionString
#if os(OSX) //FIXME: Ugly hack, see issue #7
    if #available(OSX 10.10, OSXApplicationExtension 10.10, *) {
        let version = info.operatingSystemVersion
        return (description, version.majorVersion, version.minorVersion, version.patchVersion, build)
    } else {
        let version = systemVersion?["ProductVersion"] as? String
        let parts = version?.characters.split(separator: ".") ?? []
        let major = parts.count > 0 ? Int(String(parts[0])) ?? -1 : -1
        let minor = parts.count > 1 ? Int(String(parts[1])) ?? -1 : -1
        let patch = parts.count > 2 ? Int(String(parts[2])) ?? -1 : -1
        return (description, major, minor, patch, build)
    }
#else
    if info.responds(to: #selector(getter: ProcessInfo.operatingSystemVersion)) {
        let version = info.operatingSystemVersion
        return (description, version.majorVersion, version.minorVersion, version.patchVersion, build)
    } else {
        let version = systemVersion?["ProductVersion"] as? String
        let parts = version?.characters.split(separator: ".") ?? []
        let major = parts.count > 0 ? Int(String(parts[0])) ?? -1 : -1
        let minor = parts.count > 1 ? Int(String(parts[1])) ?? -1 : -1
        let patch = parts.count > 2 ? Int(String(parts[2])) ?? -1 : -1
        return (description, major, minor, patch, build)
    }
#endif
}()


/// A collection of any available device IDs.
///
/// In OS X, only the `vendor` ID is available.
///
/// In iOS and tvOS, the `advertising` ID is available as well, but disabled by default. To enable, see the note below.
///
/// Other OSes currently return empty strings for both IDs.
///
/// - important: LogKit honors the iOS/tvOS `ASIdentifierManager.advertisingTrackingEnabled` flag. If an end user has
///              disabled advertising tracking on their device, LogKit will substitute an empty string for the
///              `advertising` ID.
/// - note: The iOS/tvOS advertising ID is disabled by default to prevent triggering [IDFA requirements][idfa] in apps
///         that do not require an advertising ID. To enable the `advertising` ID, the `-DLogKitAdvertisingIDDisabled`
///         compiler flag must be removed from the LogKit Project build settings. The flag is found in the "Swift
///         Compiler - Custom Flags" section of the Build Settings page, under "Other Swift Flags". Be sure to search in
///         the *LogKit Project* build settings, not your app's project settings. Additionally, be sure to add/remove
///         the flag from the LogKit *Project* global build settings, not one of LogKit's OS-specific targets.
///
/// [idfa]: https://developer.apple.com/library/ios/documentation/LanguagesUtilities/Conceptual/iTunesConnect_Guide/Chapters/SubmittingTheApp.html#//apple_ref/doc/uid/TP40011225-CH33-SW8
internal let LK_DEVICE_IDS: (vendor: String, advertising: String) = {
#if os(OSX)
    var timeSpec = timespec(tv_sec: 0, tv_nsec: 0)
    var bytes = Array<CUnsignedChar>(repeating: 0, count: 16)
    guard gethostuuid(&bytes, &timeSpec) == 0 else {
        return ("", "")
    }
    let nsuuid = NSUUID(uuidBytes: bytes)
    return (nsuuid.uuidString, "")
#elseif os(iOS) || os(tvOS)
    let vendorID = UIDevice.current.identifierForVendor?.uuidString ?? ""
    #if LogKitAdvertisingIDDisabled
        let advertisingID = ""
    #else
        let adManager = ASIdentifierManager.shared()
        let advertisingID = (adManager?.isAdvertisingTrackingEnabled)! ? adManager?.advertisingIdentifier.uuidString : ""
    #endif
    return (vendorID, advertisingID)
#else
    return ("", "")
#endif
}()


//MARK: Shared Extensions

internal extension FileManager {

    /// This method attempts to ensure that a file is available at the specified URL. It will attempt to create an
    /// empty file if one does not already exist at that location.
    ///
    /// - parameter                at: The URL of the file to ensure availability of.
    /// - parameter createDirectories: Indicates whether intermediate directories should be created if
    ///                                necessary, before creating the file, if is does not exist.
    ///
    /// - throws: `NSError` with domain `NSURLErrorDomain`
    internal func ensureFile(at URL: Foundation.URL, createDirectories: Bool = true) throws {
        assert(URL.isFileURL, "URL must be a file system URL")

        let dirPath = URL.deletingLastPathComponent().path
        let filePath = URL.path
        guard dirPath.characters.count > 0 && filePath.characters.count > 0 else {
            assertionFailure("Invalid path: \(URL.absoluteString)")
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSURLErrorKey: URL])
        }

        do { try FileManager.default.createDirectory(atPath: dirPath,
                                                                      withIntermediateDirectories: createDirectories,
                                                                      attributes: nil)
        } catch let error {
            assertionFailure("Could not create directory (maybe access denied?) at path: \(dirPath)")
            throw error
        }

        if !FileManager.default.fileExists(atPath: filePath) { // Must check first to avoid overwriting.
            guard FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil) else {
                assertionFailure("Could not create file (maybe access denied?) at path: \(filePath)")
                throw NSError(domain: NSURLErrorDomain,
                              code: NSURLErrorCannotCreateFile,
                              userInfo: [NSURLErrorKey: URL])
            }
        }
    }

}


internal extension Calendar {

    /// Returns whether the given date is the same date as "today".
    /// Exists as a compatibility shim for older operating systems.
    internal func isDateSameAsToday(_ date: Date) -> Bool {
        if #available(iOS 8.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
            return self.isDateInToday(date)
        }else{
            let today = Date()
            let todayDay = (self as NSCalendar).ordinality(of: .day, in: .year, for: today)
            let todayYear = (self as NSCalendar).ordinality(of: .year, in: .era, for: today)
            let dateDay = (self as NSCalendar).ordinality(of: .day, in: .year, for: date)
            let dateYear = (self as NSCalendar).ordinality(of: .year, in: .era, for: date)
            return todayYear == dateYear && todayDay == dateDay
        }
    }

}
