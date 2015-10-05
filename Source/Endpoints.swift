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


/// Objects that conform to the `LXEndpoint` protocol may be used by an `LXLogger` as log entry destinations.
public protocol LXEndpoint {
    /// Only log entries of this level or above will be written to this endpoint.
    var minimumPriorityLevel: LXPriorityLevel { get }
    /// The date formatter that this endpoint will use to convert an entry instance's `dateTime` to a string.
    var dateFormatter: LXDateFormatter { get }
    /// The entry formatter that this endpoint will use to convert an entry instance to a string.
    var entryFormatter: LXEntryFormatter { get }
    /// Indicates whether this endpoint requires a newline character appended to each converted log entry instance.
    var requiresNewlines: Bool { get }

    /**
    Write the converted log entry string to the endpoint.

    - parameter string: The log entry, after being converted by the `entryFormatter`.
    */
    func write(string: String) -> Void

}
