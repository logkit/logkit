# Change Log


### [2.3.2](https://github.com/logkit/logkit/releases/tag/2.3.2)

Fix for memory leak.

#### Fixed

* Memory leak in Entry Formatters (#26 thanks @rhcpfan)
* Potential strong reference cycles in Endpoints


### [2.3.1](https://github.com/logkit/logkit/releases/tag/2.3.1)

Fix for Carthage builds on OSX and iOS.

#### Added

* New automated testing to ensure Carthage builds and CocoaPods lints successfully

#### Fixed

* Carthage builds, due to incorrect OSX and iOS scheme settings (#20 #21 thanks @mark-anders)


### [2.3.0](https://github.com/logkit/logkit/releases/tag/2.3.0)

New APIs, IDFA fix, Swift 2.2, more tests!

#### Updated

* Now with Swift 2.2 (#18 thanks @JackoPlane)

#### Added

* Support for manually rotating `LXRotatingFileEndpoint` instances (#15 thanks @rabidaudio)
* More test targets for Travis (iOS, tvOS, watchOS)
* More unit tests
* Initial support for Swift Package Manager

#### Fixed

* Disabled Advertising ID by default to eliminate IDFA requirements (#16 #17 thanks @rabidaudio)


### [2.2.0](https://github.com/logkit/logkit/releases/tag/2.2.0)

New API for accessing the log file URLs used by the family of File Endpoints. All changes are backward-compatible.

#### Added

* `directoryURL` and `currentURL` properties of `LXRotatingFileEndpoint`, `LXFileEndpoint`, and `LXDatedFileEndpoint` are now publicly accessible (#11 thanks @rabidaudio)
* The File Endpoints now post notifications directly before and after automatically rotating log files


### [2.1.1](https://github.com/logkit/logkit/releases/tag/2.1.1)

Bugfix update

#### Fixed

* `LXFileEndpoint` now honors its `shouldAppend` initialization parameter (#9 thanks @csmann)
* `LXConsoleEndpoint` synchronicity issues resolved by outputting to `stderr` (#10 thanks @mark-anders)


### [2.1.0](https://github.com/logkit/logkit/releases/tag/2.1.0)

tvOS support

#### Added

* Support for projects targeting tvOS
* Added a Logger test, which also tests generating Log Entries


### [2.0.2](https://github.com/logkit/logkit/releases/tag/2.0.2)

Documentation updates

#### Fixed

* Revised the ordering of products in Xcode to match the documentation
* Minor documentation typo fixes


### [2.0.1](https://github.com/logkit/logkit/releases/tag/2.0.1)

HTTP JSON Endpoint initializer fix; improved documentation

#### Updated

* All source code documentation has been reviewed and improved
* The `LXEntryFormatter.jsonFormatter()` has been made private, as it does currently behave as developers might expect. Hopefully, this formatter can be made publicly available again in the future. See #8.

#### Fixed

* `LXHTTPJSONEndpoint`'s designated initializer parameter `dateFormatter` now correctly defaults to `.ISO8601DateTimeFormatter()`


### [2.0.0](https://github.com/logkit/logkit/releases/tag/2.0.0)

LogKit 2 is a complete overhaul of the LogKit framework. LogKit 2 comes with new and enhanced Endpoints, watch OS compatibility, and more detailed logging information.

#### Added

* Swift 2 and Xcode 7 support
* watchOS support
* Rotating File Endpoint - switches to a new file when the current file approaches a maximum size
* More Log Entry properties, including OS version, device model/type, and device IDs
* A variety of built-in datetime and entry formatting options, which are easily extended

#### Updated

* Many objects have been renamed:
  * `LXLogEndpoint` is now `LXEndpoint`
  * `LXLogConsoleEndpoint` is now `LXConsoleEndpoint`
  * `LXLogFileEndpoint` is now `LXFileEndpoint`
  * `LXLogDatedFileEndpoint` is now `LXDatedFileEndpoint`
  * `LXLogHTTPEndpoint` is now `LXHTTPEndpoint`
  * `LXLogHTTPJSONEndpoint` is now `LXHTTPJSONEndpoint`
  * `LXLogLevel` is now `LXPriorityLevel`
  * `LXLogEntryFormatter` is now `LXEntryFormatter`
* The `LXLogEntry` property `logLevel` has been renamed to `level`
* The JSON Endpoint's behavior has been updated in several ways:
  * The `level` property is now included as `level` (instead of `logLevel`)
  * The `userInfo` property is now included as a dictionary under the `userInfo` key
  * Uploads now consist of a JSON dictionary, with an item `entries` that includes an array of Log Entries
* Date and entry formatting are now performed by `LXDateFormatter` and `LXEntryFormatter` objects
  * Each formatter object now has a variety of built-in output formats
* The Console Endpoint may now be set as synchronous or asynchronous at init time, and will never jumble log entries
  * The Serial Console Endpoint has been removed. Use the Console Endpoint asynchronously instead
* The Dated File Endpoint now rotates to a new file automatically at midnight UTC
* The HTTP and JSON Endpoints now persist pending entries until successful upload, so that log messages will not get lost on a bad network
  * Entries are also persisted between application runs, so that remaining entries may be uploaded at next run


### [1.1.1](https://github.com/logkit/logkit/releases/tag/1.1.1)

Documentation updates

#### Fixed

* Revised the ordering of products in Xcode to match the documentation
* Minor README documentation updates


### [1.1.0](https://github.com/logkit/logkit/releases/tag/1.1.0)

This release facilitates compatibility with LogKit 2.

#### Updated

* Most classes have been renamed to match their LogKit 2 counterparts. Compatibility aliases have been added so that applications already using LogKit 1.0.x will continue to work properly with 1.1.
  * `LXLogEndpoint` is now `LXEndpoint`
  * `LXLogConsoleEndpoint` is now `LXConsoleEndpoint`
  * `LXLogSerialConsoleEndpoint` is now `LXSerialConsoleEndpoint`
  * `LXLogFileEndpoint` is now `LXFileEndpoint`
  * `LXLogDatedFileEndpoint` is now `LXDatedFileEndpoint`
  * `LXLogHTTPEndpoint` is now `LXHTTPEndpoint`
  * `LXLogHTTPJSONEndpoint` is now `LXHTTPJSONEndpoint`
  * `LXLogLevel` is now `LXPriorityLevel`
  * `LXLogEntryFormatter` is now `LXEntryFormatter`
* The log entry properties `logLevel` has been renamed to `level`
  * `logLevel` remains available for compatibility, but will be removed in LogKit 2
* The JSON Endpoint now uploads the `level` properties as `level` (instead of `logLevel`)
  * `logLevel` is also included for compatibility, but will be removed in LogKit 2


### [1.0.4](https://github.com/logkit/logkit/releases/tag/1.0.4)

OS X 10.9 and iOS 7 GCD Fix

#### Fixed

* OS X 10.9 and iOS 7 do not support QOS classes; now using global queue priorities (#1)


### [1.0.3](https://github.com/logkit/logkit/releases/tag/1.0.3)

Updated Project settings

#### Updated

* Changed Org and bundle ID to LogKit


### [1.0.2](https://github.com/logkit/logkit/releases/tag/1.0.2)

Enhanced README

#### Updated

* More usage detail in README.md
* More license detail in README.md


### [1.0.1](https://github.com/logkit/logkit/releases/tag/1.0.1)

Testing and documentation maintenance release

#### Added

* A few more test cases in Xcode
* Travis-CI automated testing and badge
* CocoaPods badge

#### Updated

* Xcode-native documentation to cover some undocumented code

#### Fixed

* Xcode project schemes that weren't being shared


### [1.0.0](https://github.com/logkit/logkit/releases/tag/1.0.0)

Initial release
