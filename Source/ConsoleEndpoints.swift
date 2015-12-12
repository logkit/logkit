// ConsoleEndpoints.swift
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


//MARK: Console Writer Protocol

/// An internal protocol that facilitates `LXConsoleEndpoint` in operating either synchronously or asynchronously.
private protocol LXConsoleWriter {
    func writeData(data: NSData) -> Void
}


//MARK: Console Endpoint

/// An Endpoint that prints Log Entries to the console (`stderr`) in either a synchronous or asynchronous fashion.
public class LXConsoleEndpoint: LXEndpoint {
    /// The minimum Priority Level a Log Entry must meet to be accepted by this Endpoint.
    public var minimumPriorityLevel: LXPriorityLevel
    /// The formatter used by this Endpoint to serialize a Log Entry’s `dateTime` property to a string.
    public var dateFormatter: LXDateFormatter
    /// The formatter used by this Endpoint to serialize each Log Entry to a string.
    public var entryFormatter: LXEntryFormatter
    /// This Endpoint requires a newline character appended to each serialized Log Entry string.
    public let requiresNewlines: Bool = true

    /// The actual output engine.
    private let writer: LXConsoleWriter

    /**
    Initialize a Console Endpoint.

    A synchronous Console Endpoint will write each Entry to the console before continuing with application execution, which makes
    debugging much easier. An asynchronous Console Endpoint may continue execution before every Entry is written to the console,
    which will improve performance.

    - parameter synchronous: (optional) Indicates whether the application should wait for each Entry to be printed to the
    console before continuing execution. Defaults to `true`.
    - parameter minimumPriorityLevel: (optional) The minimum Priority Level a Log Entry must meet to be accepted by this Endpoint.
    Defaults to `.All`.
    - parameter dateFormatter: (optional) The formatter used by this Endpoint to serialize a Log Entry’s `dateTime` property to a
    string. Defaults to `.standardFormatter()`.
    - parameter entryFormatter: (optional) The formatter used by this Endpoint to serialize each Log Entry to a string. Defaults
    to `.standardFormatter()`.
    */
    public init(
        synchronous: Bool = true,
        minimumPriorityLevel: LXPriorityLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        self.minimumPriorityLevel = minimumPriorityLevel
        self.dateFormatter = dateFormatter
        self.entryFormatter = entryFormatter

        switch synchronous {
        case true:
            self.writer = LXSynchronousConsoleWriter()
        case false:
            self.writer = LXAsynchronousConsoleWriter()
        }
    }

    /// Writes a serialized Log Entry string to the console (`stderr`).
    public func write(string: String) {
        guard let data = string.dataUsingEncoding(NSUTF8StringEncoding) else {
            assertionFailure("Failure to create data from entry string")
            return
        }
        self.writer.writeData(data)
    }

}


//MARK: Console Writers

/// A private console writer that facilitates synchronous output.
private class LXSynchronousConsoleWriter: LXConsoleWriter {

    /// The console's (`stderr`) file handle.
    private let handle = NSFileHandle.fileHandleWithStandardError()

    /// Clean up.
    deinit { self.handle.closeFile() }

    /// Writes the data to the console (`stderr`).
    private func writeData(data: NSData) {
        self.handle.writeData(data)
    }

}


/// A private console writer that facilitates asynchronous output.
private class LXAsynchronousConsoleWriter: LXConsoleWriter {
//TODO: open a dispatch IO channel to stderr instead of one-off writes?

    /// Writes the data to the console (`stderr`).
    private func writeData(data: NSData) {
        guard let dispatchData = dispatch_data_create(data.bytes, data.length, nil, nil) else {
            assertionFailure("Failure to create data from entry string")
            return
        }
        dispatch_write(STDERR_FILENO, dispatchData, LK_LOGKIT_QUEUE, { _, _ in })
    }

}
