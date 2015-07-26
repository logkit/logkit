// Endpoints.swift
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


public protocol LXEndpoint {
    /// Only log entries of this level or above will be written to this endpoint.
    var minimumLogLevel: LXLogLevel { get }
    /// The date formatter that this endpoint will use to convert an entry's `dateTime` to a string.
    var dateFormatter: LXDateFormatter { get }
    /// The entry formatter that this endpoint will use to convert an entry to a string.
    var entryFormatter: LXEntryFormatter { get }

    var requiresNewlines: Bool { get }
    /**
    Write the formatted log entry to the endpoint.

    :param: entryString The log entry, after being formatted by the `entryFormatter`.
    */
    func write(entryString: String) -> Void
    
}


internal enum LXEndpointError: ErrorType, CustomStringConvertible {
    case CustomError(message: String)

    var description: String {
        switch self {
        case .CustomError(let message): return message
        }
    }

}
