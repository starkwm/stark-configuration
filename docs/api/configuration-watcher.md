# Watch configuration files

[Documentation index](../index.md#api-reference)

`ConfigurationWatcher` watches a file and the closest parent directory that exists. It handles writes, atomic replacement, deletion, and first creation, even if parent directories are missing.

## Create a watcher

Create and keep the watcher on the main actor. Pass the file URL and a callback that reloads your configuration:

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

Keep the returned watcher for as long as you need notifications. The callback runs on the main actor and takes no arguments. Replace the print statement with code that [loads and decodes your configuration](jsonc.md).

The callback must handle missing files and invalid contents. Activity in the watched directory can also trigger it when the configuration file has not changed. If the callback captures the watcher's owner, use a weak capture to avoid a retain cycle.

## Start and stop

Call `start()` to watch for changes. Calling it while already started has no effect. Load the initial configuration yourself. Starting the watcher does not invoke the callback.

Call `stop()` before discarding the watcher. It cancels pending reloads and filesystem watches. Repeated calls are safe, and `start()` resumes watching after a stop.

Neither method throws. If the watcher cannot open a file or directory, it skips that target without reporting an error.

## Reload behavior

The watcher waits for 100 milliseconds without an event before calling the callback. Each new event restarts the delay. Before calling the callback, the watcher reopens the file and directory to follow replaced files and newly created directories.

The watcher does not read or apply configuration values. Your application decides whether to retain the last valid configuration when a reload fails.
