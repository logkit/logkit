// Levels.swift
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


/// Logging Priority Levels are described below, in order of lowest-to-highest priority:
///
/// - `All`     : Special value that includes all priority levels
/// - `Debug`   : Programmer debugging
/// - `Info`    : Programmer information
/// - `Notice`  : General notice
/// - `Warning` : Event may affect user experience at some point, if not corrected
/// - `Error`   : Event will definitely affect user experience
/// - `Critical`: Event may crash application
/// - `None`    : Special value that excludes all priority levels
public enum LXPriorityLevel: Int, Comparable, CustomStringConvertible {

    // These levels are designed to match ASL levels
    // https://developer.apple.com/library/mac/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/LoggingErrorsAndWarnings.html

    /// A special value that includes all Priority Levels.
    case all      =  100
    /// Programmer debugging
    case debug    =    7
    /// Programmer information
    case info     =    6
    /// General notice
    case notice   =    5
    /// Event may affect user experience at some point, if not corrected
    case warning  =    4
    /// Event will definitely affect user experience
    case error    =    3
    /// Event may crash application
    case critical =    2
    /// A special value that excludes all Priority Levels
    case none     = -100

    /// A string representation of the Priority Level.
    public var description: String {
        switch self {
        case .all:
            return "All"
        case .debug:
            return "Debug"
        case .info:
            return "Info"
        case .notice:
            return "Notice"
        case .warning:
            return "Warning"
        case .error:
            return "Error"
        case .critical:
            return "Critical"
        case .none:
            return "None"
        }
    }
    
}

/// Determines if two Priority Levels are equal.
public func ==(lhs: LXPriorityLevel, rhs: LXPriorityLevel) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

/// Performs a comparison between two Priority Levels.
public func <(lhs: LXPriorityLevel, rhs: LXPriorityLevel) -> Bool {
    return lhs.rawValue > rhs.rawValue // Yes, this is reversed intentionally
}
