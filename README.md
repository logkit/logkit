# LogKit

[http://www.logkit.info/][website]

LogKit is a logging framework built to be **simple** to get started with, **efficient** to execute, **safe** for shipping code, and **extensible** for flexibility. It is written in pure Swift and is suitable for iOS and OS X application logging. For a developer looking for more power than `println()`, LogKit takes just a moment to get started with, and comes ready to log to the console, a file, an HTTP service, or all three. Need to log to somewhere else? Defining your own Endpoint is easy too.

This documents contains just a few tips to get you started with LogKit. To learn everything else, check the [project website][website].

[![Build Status](https://travis-ci.org/logkit/logkit.svg?branch=master)](https://travis-ci.org/logkit/logkit)
[![CocoaPods](https://img.shields.io/badge/pod-1.0.1-blue.svg)](https://cocoapods.org/pods/LogKit)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## Requirements

LogKit is available for Swift projects targeting iOS 7+ and OS X 10.9+. Requires Xcode 6.3+ and Swift 1.2.

## Installation

There are a few ways to install LogKit. Below are some tips, but for full details, see the [installation guide][install].

### CocoaPods

> Supports iOS 8+, OS X 10.9+

Include LogKit in your Podfile:

```ruby
use_frameworks!
pod 'LogKit', '~> 1.0'
```

For more information on getting started with CocoaPods, read the [guide][cocoapods].

### Carthage

> Supports iOS 8+, OS X 10.9+

Include LogKit in your Cartfile:

```
github "logkit/logkit" >= 1.0
```

For more information on getting started with Carthage, visit the [repo][carthage].

### Embedded Framework

> Supports iOS 8+, OS X 10.9+

Include `LogKit.xcodeproj` within your project (second level, below your project root, as a sub-project). Select your target, and add LogKit as an Embedded Binary in the General tab. Choose the top LogKit for an iOS target, or the bottom LogKit for OS X.

### Source

> Supports iOS 7+, OS X 10.9+
>
> Integrating the LogKit source file is the only way to include LogKit in projects targeting iOS 7. When this installation method is used, skip the `import LogKit`.

Add `LogKit.swift` (found in the `Sources` directory) to your project. No other steps are necessary for installation.

## Usage

LogKit is easy to get started with. Use the Quick Start below to get started now, then check out the [usage guide][usage] for full details of everything LogKit can do.

### Quick Start

Near the top of your `AppDelegate.swift` file, add the following two lines:

```swift
import LogKit

let log = LXLogger()
```

This will import the LogKit framework and create a global Logger instance. This Logger will initialize with a standard Console Endpoint set to log all messages in the default format.

You can now log from anywhere in your project:

```swift
log.info("Hello Internet!")

// 2015-06-25 07:36:01.638000 [INFO] applicationDidFinishLaunching <AppDelegate.swift:23> Hello Internet!
```

Now you're logging! You can use the `debug`, `info`, `notice`, `warning`, `error`, and `critical` Logger methods.

You can add and configure more Endpoints later, such as the included File and HTTP Service Endpoints. See the [Endpoints documentation][endpoints] for more details.

## Contributing

LogKit welcomes contributions! Please see [CONTRIBUTING.md][contrib] for more info.

## License

LogKit is licensed under the permissive [ISC License][license].


[website]: http://www.logkit.info/
[install]: http://www.logkit.info/docs/1.0/installation/
[cocoapods]: https://guides.cocoapods.org/using/using-cocoapods.html
[carthage]: https://github.com/Carthage/Carthage
[usage]: http://www.logkit.info/docs/1.0/usage/
[endpoints]: http://www.logkit.info/docs/1.0/endpoints/
[contrib]: https://github.com/logkit/logkit/blob/master/CONTRIBUTING.md
[license]: https://github.com/logkit/logkit/blob/master/LICENSE.txt
