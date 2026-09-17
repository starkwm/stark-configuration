# Getting started

[Documentation index](index.md)

## Requirements

- macOS 26 or later
- Swift 6.2 or later

## Installation

Add `https://github.com/starkwm/stark-configuration.git` as a Swift package dependency and link the `StarkConfiguration` product to your target.

## Read a configuration file

Define your configuration type, read the file, and normalise its contents before decoding:

```swift
import Foundation
import StarkConfiguration

struct Configuration: Decodable {
  var theme: String
}

let url = URL(fileURLWithPath: "config.jsonc")
let data = try Data(contentsOf: url)
let json = try JSONC.normalized(data, rejectingDuplicateKeys: true)
let configuration = try JSONDecoder().decode(Configuration.self, from: json)
```

Your application chooses the file location and handles loading and decoding errors. StarkConfiguration does not save or rewrite the file.

See [Read JSONC](api/jsonc.md) for supported syntax and validation, and [Watch configuration files](api/configuration-watcher.md) to reload after changes.
