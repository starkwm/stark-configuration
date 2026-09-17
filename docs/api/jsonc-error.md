# Handle JSONC errors

[Documentation index](../index.md#api-reference)

`JSONCError` reports syntax and duplicate-key errors from [JSONC](jsonc.md). It conforms to `LocalizedError` and `Sendable` and has no public initializer.

## Error description

`errorDescription` is a read-only `String?` containing the diagnostic message. Use `localizedDescription` to display it. Syntax diagnostics include a one-based byte position. Duplicate-key diagnostics include the decoded key name.

Examples of diagnostic messages:

- `Unterminated block comment at byte 1.`
- `Unexpected comma at byte 2.`
- `Duplicate configuration key: theme.`

```swift
import Foundation
import StarkConfiguration

do {
  let data = Data(#"{"theme":1,"theme":2}"#.utf8)
  _ = try JSONC.normalized(data, rejectingDuplicateKeys: true)
} catch let error as JSONCError {
  print(error.localizedDescription)
} catch {
  print("Invalid JSON: \(error.localizedDescription)")
}
```

JSON syntax validation can also throw Foundation errors. Decoding into your configuration type can throw `DecodingError`. Handle these alongside `JSONCError`, as shown above.
