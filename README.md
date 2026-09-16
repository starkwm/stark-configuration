# StarkConfiguration

Shared configuration-file utilities for Stark Software. Requires Swift 6.2 and macOS 26.

`JSONC.normalized(_:)` replaces comments and trailing commas with spaces, preserving byte offsets and line endings. Quoted strings remain unchanged. The caller decodes and validates its application model. Duplicate keys remain accepted by default; pass `rejectingDuplicateKeys: true` to validate JSON syntax and reject duplicate keys within each object. Escaped key spellings compare as decoded strings.

`JSONC.rejectDuplicateKeys(_:)` validates plain JSON, including scalar fragments, before checking keys. Use it for runtime values that are already JSON rather than JSONC. Diagnostics use `LocalizedError`.

`ConfigurationWatcher` runs on the main actor. Initialise it with a file URL and callback, then call `start()`. It watches the file and nearest existing parent directory, reinstalls watches after events, and debounces callbacks by 100 ms. This supports atomic replacement and files whose parent directories do not exist yet. Call `stop()` before discarding the watcher. Start and stop are idempotent; stopping cancels pending callbacks. Parent-directory events can also trigger callbacks, so consumers decide whether and how to reload.

Application models, configuration paths, validation rules and reload policy belong to consumers.

Run `swift test --disable-xctest --no-parallel` to test JSONC handling and real filesystem notifications.
