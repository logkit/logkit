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


public enum LXConsoleEndpointType {
    case Standard
    case Serialized(async: Bool)
}


public class LXConsoleEndpoint: LXEndpoint {
    public var minimumLogLevel: LXLogLevel
    public var dateFormatter: LXDateFormatter
    public var entryFormatter: LXEntryFormatter
    public let requiresNewlines: Bool = true

    private let consoleType: LXConsoleEndpointType

    public init(
        type: LXConsoleEndpointType = .Standard,
        minimumLogLevel: LXLogLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        self.consoleType = type
        self.minimumLogLevel = minimumLogLevel
        self.dateFormatter = dateFormatter
        self.entryFormatter = entryFormatter
    }

    public func write(entryString: String) {
        switch self.consoleType {
        case .Standard:
            print(entryString, appendNewline: false)
        case .Serialized(let async):
            if async {
                guard let data = entryString.dispatchDataUsingEncoding(NSUTF8StringEncoding) else {
                    assertionFailure("Failure to create dispatch_data_t from entry string")
                    return
                }
                dispatch_write(STDOUT_FILENO, data, defaultQueue, { data, errno in })
            } else {
                guard let data = entryString.dataUsingEncoding(NSUTF8StringEncoding) else {
                    assertionFailure("Failure to create data from entry string")
                    return
                }
                NSFileHandle.fileHandleWithStandardOutput().writeData(data)
            }
        }
    }

}
