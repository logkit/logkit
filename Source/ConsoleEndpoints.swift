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


/// An internal protocol that facilitates `LXConsoleEndpoint` in operating either synchronously or asynchronously.
private protocol LXConsoleWriter {
    func writeData(data: NSData) -> Void
}


/// An endpoint that prints log entries to the console (stdout) in either a synchronous or asynchronous fashion.
public class LXConsoleEndpoint: LXEndpoint {
    public var minimumPriorityLevel: LXPriorityLevel
    public var dateFormatter: LXDateFormatter
    public var entryFormatter: LXEntryFormatter
    public let requiresNewlines: Bool = true

    /// The actual output engine.
    private let writer: LXConsoleWriter

    /**
    Initialize a console endpoint.
    
    A synchronous console endpoint will write each entry to the console before continuing with application execution, which makes
    debugging much easier. An asynchronous console endpoint may continue execution before every entry is written to the console,
    which will improve performance.
    
    - parameters:
      - synchronous: (optional) Indicates whether the application should wait for each message to be printed to the console
      before continuing execution. Defaults to `true`.
      - minimumPriorityLevel: (optional) Only log entries of this level or above will be written to this endpoint. Defaults to
      `All`.
      - dateFormatter: (optional) The date formatter that this endpoint will use to convert an entry's `dateTime` to a string.
      Defaults to `LXDateFormatter.standardFormatter()`.
      - entryFormatter: (optional) The entry formatter that this endpoint will use to convert an entry instnace to a string.
      Defaults to `LXEntryFormatter.standardFormatter()`.
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

    /// Writes an entry to the console (stdout).
    public func write(string: String) {
        guard let data = string.dataUsingEncoding(NSUTF8StringEncoding) else {
            assertionFailure("Failure to create data from entry string")
            return
        }
        self.writer.writeData(data)
    }

}


/// A private console writer that facilitates synchronous output.
private class LXSynchronousConsoleWriter: LXConsoleWriter {

    /// The console's (stdout) file handle.
    private let stdoutHandle = NSFileHandle.fileHandleWithStandardOutput()

    /// Clean up.
    deinit { self.stdoutHandle.closeFile() }

    /// Writes the data to the console (stdout).
    private func writeData(data: NSData) {
        self.stdoutHandle.writeData(data)
    }

}


/// A private console writer that facilitates asynchronous output.
private class LXAsynchronousConsoleWriter: LXConsoleWriter {
//TODO: open a dispatch IO channel to stdout instead of one-off writes?

    /// Writes the data to the console (stdout).
    private func writeData(data: NSData) {
        guard let dispatchData = dispatch_data_create(data.bytes, data.length, nil, nil) else {
            assertionFailure("Failure to create data from entry string")
            return
        }
        dispatch_write(STDOUT_FILENO, dispatchData, LK_LOGKIT_QUEUE, { _, _ in })
    }

}
