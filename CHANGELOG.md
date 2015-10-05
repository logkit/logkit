# Change Log


### [2.0.0](https://github.com/logkit/logkit/releases/tag/2.0.0)

LogKit 2 is a complete overhaul of the LogKit framework. LogKit 2 comes with new and enhanced Endpoints, watch OS compatibility, and more detailed logging information.

#### Added

* Swift 2 support
* watchOS support
* Rotating File Endpoint - switches to a new file when the current file approaches a maximum size
* More Log Entry properties, including OS version, device model/type, and device IDs

#### Updated

* Many objects have been renamed (see the 1.1.0 release notes below -- they all apply to LogKit 2 as well)
* The Console Endpoint may now be set as synchronous or asynchronous at init time, and will never jumble log entries
* The Dated File Endpoint now rotates to a new file automatically at midnight
* The HTTP and JSON Endpoints now persist pending uploads between runs, so that log messages will not get lost on a bad network
* The JSON Endpoint now includes all `userInfo` items as a second-level dictionary under the `userInfo` key


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
