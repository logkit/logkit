// Levels.swift
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


/**
Logging Priority Levels are described below, in order of lowest-to-highest priority:

- `All`: Special value that includes all priority levels
- `Debug`: Programmer debugging
- `Info`: Programmer information
- `Notice`: General notice
- `Warning`: Event may affect user experience at some point, if not corrected
- `Error`: Event will definitely affect user experience
- `Critical`: Event may crash application
- `None`: Special value that excludes all priority levels
*/
public enum LXPriorityLevel: Int, Comparable, CustomStringConvertible {
    // These levels are designed to match ASL levels
    // https://developer.apple.com/library/mac/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/LoggingErrorsAndWarnings.html

    /// A special value that includes all Priority Levels.
    case All      =  100
    /// Programmer debugging
    case Debug    =    7
    /// Programmer information
    case Info     =    6
    /// General notice
    case Notice   =    5
    /// Event may affect user experience at some point, if not corrected
    case Warning  =    4
    /// Event will definitely affect user experience
    case Error    =    3
    /// Event may crash application
    case Critical =    2
    /// A special value that excludes all Priority Levels
    case None     = -100

    /// A string representation of the Priority Level.
    public var description: String {
        switch self {
        case .All:
            return "All"
        case .Debug:
            return "Debug"
        case .Info:
            return "Info"
        case .Notice:
            return "Notice"
        case .Warning:
            return "Warning"
        case .Error:
            return "Error"
        case .Critical:
            return "Critical"
        case .None:
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
