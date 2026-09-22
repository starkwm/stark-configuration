# Read JSONC

[Documentation index](../index.md#api-reference)

`JSONC.normalized` accepts JSON with comments and trailing commas and returns data for your decoder. Pass UTF-8 data read from a file or created from a string.

## Normalise JSONC

`JSONC.normalized` replaces `//` line comments, `/* ... */` block comments, and trailing commas in arrays and objects with spaces. It preserves byte offsets and line breaks. String contents stay unchanged, including comment markers inside strings. Block comments cannot be nested.

`rejectingDuplicateKeys` defaults to `false`. Normalisation alone does not fully validate JSON syntax. Decode the returned data to validate it against your configuration type. Set `rejectingDuplicateKeys: true` to also validate JSON syntax and reject duplicate keys before returning.

```swift
import Foundation
import StarkConfiguration

struct Configuration: Decodable {
  var theme: String
}

let source = """
  {
    // Use the dark theme.
    "theme": "dark",
  }
  """

let json = try JSONC.normalized(
  Data(source.utf8),
  rejectingDuplicateKeys: true
)
let configuration = try JSONDecoder().decode(Configuration.self, from: json)
```

Unterminated block comments and unexpected commas throw [JSONCError](jsonc-error.md). With duplicate-key rejection enabled, invalid JSON can also throw a Foundation parsing error.

## Reject duplicate keys

`JSONC.rejectDuplicateKeys` validates plain JSON with `JSONSerialization` before checking keys. It accepts top-level fragments such as strings, numbers, booleans, and `null`. Normalise comments and trailing commas before calling it, or use `normalized(_:rejectingDuplicateKeys:)` to do both steps.

Keys must be unique within each object. Separate objects can use the same key. The check decodes key strings, so `"key"` and `"\u006bey"` count as duplicates.

```swift
let data = Data(#"{"theme":"dark","theme":"light"}"#.utf8)

try JSONC.rejectDuplicateKeys(data) // Throws JSONCError.
```

Duplicate keys throw `JSONCError`. Invalid JSON throws a Foundation parsing error before the duplicate-key scan runs.
