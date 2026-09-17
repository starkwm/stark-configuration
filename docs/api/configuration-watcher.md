# Watch configuration files

[Documentation index](../index.md#api-reference)

`ConfigurationWatcher` watches a file and its nearest existing ancestor directory. It handles writes, atomic replacement, deletion, and first creation, including when the file's parent directories do not yet exist.

## Create a watcher

Create and retain the watcher on the main actor. Pass the file URL and a callback that reloads your configuration:

```swift
import Foundation
import StarkConfiguration

@MainActor
func watchConfiguration(at url: URL) -> ConfigurationWatcher {
  let watcher = ConfigurationWatcher(url: url) {
    print("Configuration changed")
  }
  watcher.start()
  return watcher
}
```

Keep the returned watcher for as long as you need notifications. The callback runs on the main actor and takes no arguments. Replace the print statement with your application's loading and decoding code. See [Read JSONC](jsonc.md) for decoding examples.

The callback must handle missing files and invalid contents. Activity in the watched directory can also trigger it when the configuration file has not changed. If the callback captures the watcher's owner, use a weak capture to avoid a retain cycle.

## Start and stop

Call `start()` to install filesystem watches. Calling it while already started has no effect. Load the initial configuration yourself; starting the watcher does not invoke the callback.

Call `stop()` before discarding the watcher. It cancels pending reloads and filesystem watches. Repeated calls are safe, and `start()` resumes watching after a stop.

Neither method throws. If a file or directory cannot be opened for observation, the watcher skips that target without reporting an error.

## Reload behavior

Events are debounced for 100 milliseconds. Each new event cancels the pending reload and restarts the delay. Before invoking the callback, the watcher reinstalls its watches to follow replaced files and newly created directories.

The watcher does not read or apply configuration values. Your application decides whether to retain the last valid configuration when a reload fails.
