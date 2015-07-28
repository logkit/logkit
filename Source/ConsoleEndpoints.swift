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


public class LXConsoleEndpoint: LXEndpoint {
    public var minimumLogLevel: LXLogLevel
    public var dateFormatter: LXDateFormatter
    public var entryFormatter: LXEntryFormatter
    public let requiresNewlines: Bool = true

    public init(
        minimumLogLevel: LXLogLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        self.minimumLogLevel = minimumLogLevel
        self.dateFormatter = dateFormatter
        self.entryFormatter = entryFormatter
    }

    public func write(entryString: String) {
        print(entryString, appendNewline: false)
    }

}


public class LXSerialConsoleEndpoint: LXConsoleEndpoint {
    private let async: Bool
    private lazy var stdoutHandle: NSFileHandle? = { return self.async ? nil : NSFileHandle.fileHandleWithStandardOutput() }()

    public init(
        asynchronousWriting: Bool = false,
        minimumLogLevel: LXLogLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        self.async = asynchronousWriting
        super.init(minimumLogLevel: minimumLogLevel, dateFormatter: dateFormatter, entryFormatter: entryFormatter)
    }

    deinit {
        self.stdoutHandle?.closeFile()
    }

    public override func write(entryString: String) {
        do {
            switch self.async {
            case true:
                guard let data = entryString.dispatchDataUsingEncoding(NSUTF8StringEncoding) else {
                    throw LXEndpointError.EntryEncodingError
                }
                dispatch_write(STDOUT_FILENO, data, defaultQueue, { _, _ in })
            case false: //TODO: test if this is really synchronous
                guard let data = entryString.dataUsingEncoding(NSUTF8StringEncoding) else {
                    throw LXEndpointError.EntryEncodingError
                }
                self.stdoutHandle?.writeData(data)
            }
        } catch {
            assertionFailure("Failure to create data from entry string")
        }
    }

}
