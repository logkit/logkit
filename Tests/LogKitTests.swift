// LogKitTests.swift
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
import LogKit
import XCTest


class PriorityLevelTests: XCTestCase {

//    override func setUp() {
//        super.setUp()
//    }
//
//    override func tearDown() {
//        super.tearDown()
//    }

    func testPriorities() {
        XCTAssertEqual(LXPriorityLevel.Error, LXPriorityLevel.Error, "LXPriorityLevel Comparable conformance: .Error != .Error")
        XCTAssertGreaterThan(LXPriorityLevel.Warning, LXPriorityLevel.Debug, "LXPriorityLevel Comparable conformance: .Warning !> .Debug")
        XCTAssertLessThan(LXPriorityLevel.Info, LXPriorityLevel.Notice, "LXPriorityLevel Comparable conformance: .Info !< .Notice")
    }

//    func testPerformanceExample() {
//        self.measureBlock() {
//        }
//    }

}


class ConsoleEndpointTests: XCTestCase {

    let endpoint = LXConsoleEndpoint()

    func testWrite() {
        self.endpoint.write("Hello from the Console Endpoint!")
    }

}

class FileEndpointTests: XCTestCase {

    let endpoint = LXFileEndpoint(
        fileURL: NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask).first?.URLByAppendingPathComponent("info.logkit.test", isDirectory: true).URLByAppendingPathComponent("FileEndpointTests.txt")
    )

    func testWrite() {
        self.endpoint?.write("Hello from the File Endpoint!")
    }

}

class HTTPEndpointTests: XCTestCase {

    let endpoint = LXHTTPEndpoint(URL: NSURL(string: "https://httpbin.org/post/")!, HTTPMethod: "POST")

    func testWrite() {
        self.endpoint.write("Hello from the HTTP Endpoint!")
    }

}

class LoggerTests: XCTestCase {

    let log = LXLogger()

    func testLog() {
        self.log.debug("debug")
        self.log.info("info")
        self.log.notice("notice")
        self.log.warning("warning")
        self.log.error("error")
        self.log.critical("critical")
    }

}
