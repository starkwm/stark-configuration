# StarkConfiguration

Swift utilities for reading JSON with comments and trailing commas, and watching configuration files for changes.

Requires Swift 6.2 and macOS 26.

See the [documentation](docs/index.md) for the API reference and examples.

## Usage

Add `https://github.com/starkwm/stark-configuration.git` as a Swift package dependency and link the `StarkConfiguration` product to your target.

### Read a configuration file

Define your configuration type, then normalise the file before decoding it:

```swift
import Foundation
import StarkConfiguration

struct Configuration: Decodable {
  var theme: String
}

let url = URL(fileURLWithPath: "config.jsonc")
let data = try Data(contentsOf: url)
let json = try JSONC.normalized(data)
let configuration = try JSONDecoder().decode(Configuration.self, from: json)
```

Pass `rejectingDuplicateKeys: true` to `JSONC.normalized` to reject duplicate keys. For plain JSON, use `try JSONC.rejectDuplicateKeys(data)`.

### Watch for changes

Create and keep the watcher on the main actor. Use the same file URL and handle reloads in the callback:

```swift
let watcher = ConfigurationWatcher(url: url) {
  print("Configuration changed")
}

watcher.start()
```

The watcher handles file replacement and creation. Changes in the parent directory can also trigger the callback. Call `watcher.stop()` before discarding it.
