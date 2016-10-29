// LogKitTests.swift
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

import Foundation
import XCTest
@testable import LogKit


class PriorityLevelTests: XCTestCase {

    func testPriorities() {
        XCTAssertEqual(LXPriorityLevel.error, LXPriorityLevel.error, "LXPriorityLevel: .Error != .Error")
        XCTAssertNotEqual(LXPriorityLevel.info, LXPriorityLevel.notice, "LXPriorityLevel: .Info == .Notice")
        XCTAssertEqual(
            min(LXPriorityLevel.all, LXPriorityLevel.debug, LXPriorityLevel.info, LXPriorityLevel.notice,
                LXPriorityLevel.warning, LXPriorityLevel.error, LXPriorityLevel.critical, LXPriorityLevel.none),
            LXPriorityLevel.all, "LXPriorityLevel: .All is not minimum")
        XCTAssertLessThan(LXPriorityLevel.debug, LXPriorityLevel.info, "LXPriorityLevel: .Debug !< .Info")
        XCTAssertLessThan(LXPriorityLevel.info, LXPriorityLevel.notice, "LXPriorityLevel: .Info !< .Notice")
        XCTAssertLessThan(LXPriorityLevel.notice, LXPriorityLevel.warning, "LXPriorityLevel: .Notice !< .Warning")
        XCTAssertLessThan(LXPriorityLevel.warning, LXPriorityLevel.error, "LXPriorityLevel: .Warning !< .Error")
        XCTAssertLessThan(LXPriorityLevel.info, LXPriorityLevel.critical, "LXPriorityLevel: .Error !< .Critical")
        XCTAssertEqual(
            max(LXPriorityLevel.all, LXPriorityLevel.debug, LXPriorityLevel.info, LXPriorityLevel.notice,
                LXPriorityLevel.warning, LXPriorityLevel.error, LXPriorityLevel.critical, LXPriorityLevel.none),
            LXPriorityLevel.none, "LXPriorityLevel: .None is not maximum")
    }

}


class ConsoleEndpointTests: XCTestCase {

    let endpoint = LXConsoleEndpoint()

    func testWrite() {
        self.endpoint.write("Hello from the Console Endpoint!")
    }

}

class FileEndpointTests: XCTestCase {

    var endpoint: LXFileEndpoint?
    let endpointURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .appendingPathComponent("info.logkit.test", isDirectory: true)
        .appendingPathComponent("info.logkit.test.endpoint.file", isDirectory: false)

    override func setUp() {
        super.setUp()
        self.endpoint = LXFileEndpoint(fileURL: self.endpointURL, shouldAppend: false)
        XCTAssertNotNil(self.endpoint, "Could not create Endpoint")
    }

    override func tearDown() {
        self.endpoint?.resetCurrentFile()
//        self.endpoint = nil //TODO: do we need an endpoint close method?
//        try! NSFileManager.defaultManager().removeItemAtURL(self.endpointURL)
        //FIXME: crashes because Endpoint has not deinitialized yet
        super.tearDown()
    }

    func testFileURLOutput() {
        print("\(type(of: self)) temporary file URL: \(self.endpointURL.absoluteString)")
    }

    func testRotation() {
        let startURL = self.endpoint?.currentURL
        XCTAssertEqual(self.endpointURL, startURL, "Endpoint opened with unexpected URL")
        self.endpoint?.rotate()
        XCTAssertEqual(self.endpoint?.currentURL, startURL, "File Endpoint should not rotate files")
    }

    #if !os(watchOS) // watchOS 2 does not support extended attributes
    func testXAttr() {
        let key = "info.logkit.endpoint.FileEndpoint"
        let path = self.endpoint?.currentURL.path
        XCTAssertGreaterThanOrEqual(getxattr(path!, key, nil, 0, 0, 0), 0, "The xattr is not present")
        XCTAssertEqual(removexattr(path!, key, 0), 0, "The xattr could not be removed")
    }
    #endif

    func testWrite() {
        let testString = "Hello 👮🏾 from the File Endpoint!"
        let writeCount = Array(1...4)
        writeCount.forEach({ _ in self.endpoint?.write(testString) })
        let bytes = writeCount.flatMap({ _ in testString.utf8 })
        let canonical = Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        let _ = self.endpoint?.barrier() // Doesn't return until the writes are finished.
        XCTAssert((try! Data(contentsOf: self.endpoint!.currentURL)) == canonical)
    }

}

class RotatingFileEndpointTests: XCTestCase {

    var endpoint: LXRotatingFileEndpoint?
    let endpointURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .appendingPathComponent("info.logkit.test", isDirectory: true)
        .appendingPathComponent("info.logkit.test.endpoint.rotatingFile", isDirectory: false)

    override func setUp() {
        super.setUp()
        self.endpoint = LXRotatingFileEndpoint(baseURL: self.endpointURL, numberOfFiles: 5)
        XCTAssertNotNil(self.endpoint, "Could not create Endpoint")
    }

    override func tearDown() {
        self.endpoint?.resetCurrentFile()
        super.tearDown()
    }

    func testRotation() {
        let startURL = self.endpoint?.currentURL
        self.endpoint?.rotate()
        XCTAssertNotEqual(self.endpoint?.currentURL, startURL, "URLs should not match after just one rotation")
        self.endpoint?.rotate()
        self.endpoint?.rotate()
        self.endpoint?.rotate()
        self.endpoint?.rotate()
        XCTAssertEqual(self.endpoint?.currentURL, startURL, "URLs don't match after full rotation cycle")
    }

    #if !os(watchOS) // watchOS 2 does not support extended attributes
    func testXAttr() {
        let key = "info.logkit.endpoint.RotatingFileEndpoint"
        var path = self.endpoint?.currentURL.path
        XCTAssertGreaterThanOrEqual(getxattr(path!, key, nil, 0, 0, 0), 0, "The xattr is not present")
        XCTAssertEqual(removexattr(path!, key, 0), 0, "The xattr could not be removed")
        self.endpoint?.rotate()
        path = self.endpoint?.currentURL.path
        XCTAssertGreaterThanOrEqual(getxattr(path!, key, nil, 0, 0, 0), 0, "The xattr is not present")
        XCTAssertEqual(removexattr(path!, key, 0), 0, "The xattr could not be removed")
    }
    #endif

    func testWrite() {
        self.endpoint?.resetCurrentFile()
        let testString = "Hello 🎅🏽 from the Rotating File Endpoint!"
        let writeCount = Array(1...4)
        writeCount.forEach({ _ in self.endpoint?.write(testString) })
        let bytes = writeCount.flatMap({ _ in testString.utf8 })
        let canonical = Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        let _ = self.endpoint?.barrier() // Doesn't return until the writes are finished.
        XCTAssert((try! Data(contentsOf: self.endpoint!.currentURL)) == canonical)
    }

}

class DatedFileEndpointTests: XCTestCase {

    var endpoint: LXDatedFileEndpoint?
    let endpointURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .appendingPathComponent("info.logkit.test", isDirectory: true)
        .appendingPathComponent("info.logkit.test.endpoint.datedFile", isDirectory: false)

    override func setUp() {
        super.setUp()
        self.endpoint = LXDatedFileEndpoint(baseURL: self.endpointURL)
        XCTAssertNotNil(self.endpoint, "Could not create Endpoint")
    }

    override func tearDown() {
        self.endpoint?.resetCurrentFile()
        super.tearDown()
    }

    func testRotation() {
        let startURL = self.endpoint?.currentURL
        self.endpoint?.rotate()
        XCTAssertEqual(self.endpoint?.currentURL, startURL, "Dated File Endpoint should not manually rotate files")
    }

    #if !os(watchOS) // watchOS 2 does not support extended attributes
    func testXAttr() {
        let key = "info.logkit.endpoint.DatedFileEndpoint"
        let path = self.endpoint?.currentURL.path
        XCTAssertGreaterThanOrEqual(getxattr(path!, key, nil, 0, 0, 0), 0, "The xattr is not present")
        XCTAssertEqual(removexattr(path!, key, 0), 0, "The xattr could not be removed")
    }
    #endif

    func testWrite() {
        self.endpoint?.resetCurrentFile()
        let testString = "Hello 👷🏼 from the Dated File Endpoint!"
        let writeCount = Array(1...4)
        writeCount.forEach({ _ in self.endpoint?.write(testString) })
        let bytes = writeCount.flatMap({ _ in testString.utf8 })
        let canonical = Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        let _ = self.endpoint?.barrier() // Doesn't return until the writes are finished.
        XCTAssert((try! Data(contentsOf: self.endpoint!.currentURL)) == canonical)
    }

}

class HTTPEndpointTests: XCTestCase {

    let endpoint = LXHTTPEndpoint(URL: URL(string: "https://httpbin.org/post/")!, HTTPMethod: "POST")

    func testWrite() {
        self.endpoint.write("Hello from the HTTP Endpoint!")
    }

}

class LoggerTests: XCTestCase {

    var log: LXLogger?
    var fileEndpoint: LXFileEndpoint?
    let endpointURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .appendingPathComponent("info.logkit.test", isDirectory: true)
        .appendingPathComponent("info.logkit.test.logger", isDirectory: false)
    let entryFormatter = LXEntryFormatter({ e in "[\(e.level.uppercased())] \(e.message)" }) // Nothing variable.

    override func setUp() {
        super.setUp()
        self.fileEndpoint = LXFileEndpoint(fileURL: self.endpointURL, shouldAppend: false, entryFormatter: self.entryFormatter)
        XCTAssertNotNil(self.fileEndpoint, "Failed to init File Endpoint")
        self.log = LXLogger(endpoints: [ self.fileEndpoint, ])
        XCTAssertNotNil(self.log, "Failed to init Logger")
    }

    override func tearDown() {
        self.fileEndpoint?.resetCurrentFile()
        super.tearDown()
    }

    func testLog() {
        self.log?.debug("debug")
        self.log?.info("info")
        self.log?.notice("notice")
        self.log?.warning("warning")
        self.log?.error("error")
        self.log?.critical("critical")

        let targetContent = [
            "[DEBUG] debug", "[INFO] info", "[NOTICE] notice", "[WARNING] warning", "[ERROR] error", "[CRITICAL] critical",
        ].joined(separator: "\n") + "\n"

        _ = self.fileEndpoint?.barrier() // Doesn't return until the writes are finished.

        let actualContent = try! String(contentsOf: self.fileEndpoint!.currentURL, encoding: String.Encoding.utf8)

        XCTAssertEqual(actualContent, targetContent, "Output does not match expected output")
    }

}
