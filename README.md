# LogKit

[http://www.logkit.info/][website]

LogKit is a logging framework built to be **simple** to get started with, **efficient** to execute, **safe** for shipping code, and **extensible** for flexibility. It is written in pure Swift and is suitable for OS X, iOS, tvOS, and watchOS application logging. For a developer looking for more power than `print()`, LogKit takes just a moment to get started with, and comes ready to log to the console, a file, an HTTP service, or all three. Need to log to somewhere else? Defining your own Endpoint is easy too.

This readme contains just a few tips to get you started with LogKit. To learn everything else, check the [project website][website].

[![Build Status](https://travis-ci.org/logkit/logkit.svg?branch=master)](https://travis-ci.org/logkit/logkit)
[![CocoaPods](https://img.shields.io/badge/pod-2.3.2-blue.svg)](https://cocoapods.org/pods/LogKit)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)


## Contents

* [Features](#features)
* [Requirements](#requirements)
* [Installation](#installation)
  * [CocoaPods](#cocoapods)
  * [Carthage](#carthage)
  * [Embedded](#embedded-framework)
  * [Source](#source)
* [Usage](#usage)
  * [Quick Start](#quick-start)
  * [Additional Endpoints](#additional-endpoints)
  * [Formatting](#formatting)
* [Contributing](#contributing)
* [License](#license)


## Features

* [x] Simple setup
* [x] [Comprehensive documentation][docs]
* [x] Built-in Console, File, and HTTP [Endpoints][endpoints]
* [x] Priority-filtering per Endpoint
* [x] Complete Log Entry [format customization][formatting] per Endpoint
* [x] Custom Endpoints via simple protocol conformance


## Requirements

* Project targeting OS X 10.9+, iOS 7+, tvOS 9+, or watchOS 2+
* Xcode 7.3 and Swift 2.2


## Installation

There are a few ways to install LogKit. Below are some tips, but for full details, see the [installation guide][install].

> Note: For some reason, CocoaPods removes the CocoaPods and Carthage installation instructions from this readme displayed on their website. Please visit the [installation guide][install] if you do not see these installation options.

### CocoaPods

> Supports iOS 8+, OS X 10.9+, tvOS 9+, watchOS 2+

Include LogKit in your Podfile:

```ruby
use_frameworks!
pod 'LogKit', '~> 2.3'
```

For more information on getting started with CocoaPods, read the [guide][cocoapods].

### Carthage

> Supports iOS 8+, OS X 10.9+, tvOS 9+, watchOS 2+

Include LogKit in your Cartfile:

```
github "logkit/logkit" ~> 2.3
```

For more information on getting started with Carthage, visit the [repo][carthage].

### Embedded Framework

> Supports iOS 8+, OS X 10.9+, tvOS 9+, watchOS 2+

Include `LogKit.xcodeproj` within your project (second level, below your project root, as a sub-project). Select your target, and add LogKit as an Embedded Binary in the General tab. Pick the appropriate LogKit framework for your target’s OS. Be sure to select the framework, not the tests.

### Source

> Supports iOS 7+, OS X 10.9+, tvOS 9+, watchOS 2+
>
> Integrating the LogKit source is the only way to include LogKit in projects targeting iOS 7. When this installation method is used, skip the `import LogKit`.

Add all of the `.swift` files found in the `Sources` directory to your project. No other steps are necessary for installation.


## Migrating from LogKit 1

If you have previously used LogKit 1, most of LogKit 2 will be familiar to you. However, many objects have updated names and initializers. Please review the [ChangeLog][changelog] and read the [Migration Guide][migration] to update your code for LogKit 2.


## Usage

LogKit is easy to get started with. Everything comes with convenience initializers that require the bare minimum arguments (usually no arguments) and provide sensible defaults. Get started quickly, and then customize as desired later.

Use the Quick Start below to get started now, then check out the [usage guide][usage] for details of everything LogKit can do.

### Quick Start

Near the top of your `AppDelegate.swift` file, add the following two lines:

```swift
import LogKit

let log = LXLogger()
```

This will import the LogKit framework and create a global Logger instance. This Logger will initialize with a standard Console Endpoint set to log all messages in the default format. Since the Logger instance is created in the global scope, you should only create it once (`AppDelegate.swift` is the best place).

You can now log from anywhere in your project:

```swift
log.info("Hello Internet!")

// 2015-06-25 07:36:01.638000 [INFO] applicationDidFinishLaunching <AppDelegate.swift:23> Hello Internet!
```

Now you're logging! You can use the `debug`, `info`, `notice`, `warning`, `error`, and `critical` Logger methods.

### Additional Endpoints

If you wanted to log to a file as well as the console, and you wanted the file to only receive `notice` and higher Log Entries, you could set your logger up like this:

```swift
import LogKit

let log = LXLogger(endpoints: [

    LXConsoleEndpoint(),

    LXFileEndpoint(
        fileURL: NSURL(string: /* Path to your log file */),
        minimumPriorityLevel: .Notice
    ),

])
```

You can add and configure as many [Endpoints][endpoints] as desired, such as the included File and HTTP Service Endpoints. You can also completely [customize the format][formatting] in which Log Entries are written to each Endpoint.

### Formatting

Each Endpoint has a property named `dateFormatter` that controls how an Entry's `dateTime` property will be formatted. It accepts an `LXDateFormatter` instance and is usually set at initialization time.

```swift
let log = LXLogger(endpoints: [

    LXConsoleEndpoint(
        dateFormatter = LXDateFormatter(formatString: "HH:mm:ss.SSS")
    ),

])
```

Each Endpoint also has a property named `entryFormatter` that controls how an Entry will be converted to a string for output. It accepts an `LXEntryFormatter` instance and is also usually set at initialization time.

```swift
let log = LXLogger(endpoints: [

    LXConsoleEndpoint(
        entryFormatter = LXEntryFormatter({ entry in
            return "\(entry.dateTime) [\(entry.level.uppercaseString)] \(entry.message)"
        })
    ),

])
```

See the [Entry Formatting documentation][formatting] for more details on formatting, available Log Entry properties, and `LXEntryFormatter`.


## Contributing

LogKit welcomes contributions! Please see [CONTRIBUTING.md][contrib] for more info.


## License

LogKit is licensed under the permissive [ISC License][license].


[website]: http://www.logkit.info/
[docs]: http://www.logkit.info/docs/2.3/
[install]: http://www.logkit.info/docs/2.3/installation/
[usage]: http://www.logkit.info/docs/2.3/usage/
[endpoints]: http://www.logkit.info/docs/2.3/endpoints/
[formatting]: http://www.logkit.info/docs/2.3/formatting/
[migration]: http://www.logkit.info/docs/2.3/migration/

[changelog]: https://github.com/logkit/logkit/blob/master/CHANGELOG.md
[contrib]: https://github.com/logkit/logkit/blob/master/CONTRIBUTING.md
[license]: https://github.com/logkit/logkit/blob/master/LICENSE.txt

[cocoapods]: https://guides.cocoapods.org/using/using-cocoapods.html
[carthage]: https://github.com/Carthage/Carthage
