// DatabaseEndpoints.swift
//
// Copyright (c) 2015 - 2016, Kasiel Solutions Inc. & The LogKit Project
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
import CoreData

struct Constants {
    static let daysToSave = 7
    static let daysToSaveInMil = Double(daysToSave * 24 * 60 * 60 * 1000)
}

public class LXDataBaseEndpoint: LXEndpoint {

    /// The minimum Priority Level a Log Entry must meet to be accepted by this Endpoint.
    public var minimumPriorityLevel: LXPriorityLevel
    /// The formatter used by this Endpoint to serialize a Log Entry’s `dateTime` property to a string.
    public var dateFormatter: LXDateFormatter
    /// The formatter used by this Endpoint to serialize each Log Entry to a string.
    public var entryFormatter: LXEntryFormatter
    /// This Endpoint requires a newline character appended to each serialized Log Entry string.
    public let requiresNewlines: Bool = true
    
    public func getLogs() -> Data {
        let str = PersistenceService.updateData()
        let data = str.data(using: String.Encoding.utf8)
        return data!
    }
    
    public func markingSent() {
        PersistenceService.markingSent()
    }
    
    public init(
        minimumPriorityLevel: LXPriorityLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
    ) {
        self.minimumPriorityLevel = minimumPriorityLevel
        self.dateFormatter = dateFormatter
        self.entryFormatter = entryFormatter
    }

    public func write(string: String) {
        guard let data = string.data(using: String.Encoding.utf8) else {
            assertionFailure("Failure to create data from entry string")
            return
        }
        LK_LOGKIT_QUEUE.async {
            PersistenceService.addLogs(data: data)
        }
    }
}
