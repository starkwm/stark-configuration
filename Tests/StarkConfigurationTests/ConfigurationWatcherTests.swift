import Foundation
import StarkConfiguration
import Testing

@Suite("ConfigurationWatcher", .serialized)
@MainActor
struct ConfigurationWatcherTests {
  @Test func observesWritesReplacementAndRecreation() async throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appending(path: "config.json")
    try Data("initial".utf8).write(to: url)
    var changes = 0
    let watcher = ConfigurationWatcher(url: url) { changes += 1 }
    watcher.start()
    watcher.start()
    defer { watcher.stop() }
    for atomic in [false, true, true] {
      let before = changes
      try Data(UUID().uuidString.utf8).write(to: url, options: atomic ? .atomic : [])
      try await waitUntil { changes > before }
    }
    try FileManager.default.removeItem(at: url)
    try await Task.sleep(for: .milliseconds(250))
    let before = changes
    try Data("recreated".utf8).write(to: url)
    try await waitUntil { changes > before }
  }

  @Test func observesFirstCreationThroughMissingDirectories() async throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let parent = directory.appending(path: "one/two")
    let url = parent.appending(path: "config.json")
    var changes = 0
    let watcher = ConfigurationWatcher(url: url) { changes += 1 }
    watcher.start()
    defer { watcher.stop() }
    try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
    try await waitUntil { changes > 0 }
    let before = changes
    try Data("created".utf8).write(to: url)
    try await waitUntil { changes > before }
  }

  @Test func debouncesAndCancelsPendingReloads() async throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appending(path: "config.json")
    try Data().write(to: url)
    var changes = 0
    let watcher = ConfigurationWatcher(url: url) { changes += 1 }
    watcher.start()
    defer { watcher.stop() }
    for _ in 0..<5 {
      try Data(UUID().uuidString.utf8).write(to: url)
      try await Task.sleep(for: .milliseconds(20))
    }
    try await waitUntil { changes == 1 }
    try await Task.sleep(for: .milliseconds(200))
    #expect(changes == 1)
    try Data("pending".utf8).write(to: url)
    try await Task.sleep(for: .milliseconds(20))
    watcher.stop()
    watcher.stop()
    try await Task.sleep(for: .milliseconds(200))
    #expect(changes == 1)
    watcher.start()
    try Data("restarted".utf8).write(to: url)
    try await waitUntil { changes > 1 }
  }

  private func temporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }

  private func waitUntil(_ predicate: () -> Bool) async throws {
    let deadline = ContinuousClock.now + .seconds(3)
    while !predicate(), ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(20))
    }
    #expect(predicate(), "Expected a filesystem change notification within three seconds")
  }
}
