import Foundation

/// Normalises JSON with comments and trailing commas without changing byte offsets.
public enum JSONC {
  /// Replaces comments and trailing commas with spaces. Optionally validates JSON and rejects duplicate keys.
  public static func normalized(_ data: Data, rejectingDuplicateKeys: Bool = false) throws -> Data {
    let json = try stripExtensions(data)

    if rejectingDuplicateKeys { try rejectDuplicateKeys(json) }

    return json
  }

  /// Validates JSON and rejects duplicate keys within each object.
  public static func rejectDuplicateKeys(_ data: Data) throws {
    _ = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])

    let bytes = Array(data)
    let decoder = JSONDecoder()
    var scopes: [Set<String>] = []
    var index = 0

    while index < bytes.count {
      switch bytes[index] {
      case 0x7B: scopes.append([])
      case 0x7D: scopes.removeLast()
      case 0x22:
        let start = index
        index += 1

        while index < bytes.count {
          if bytes[index] == 0x5C {
            index += 2
            continue
          }

          if bytes[index] == 0x22 { break }

          index += 1
        }

        let end = index + 1
        var next = end

        while next < bytes.count, [0x09, 0x0A, 0x0D, 0x20].contains(bytes[next]) { next += 1 }

        if next < bytes.count, bytes[next] == 0x3A, !scopes.isEmpty {
          // Decode escapes so different spellings of the same key compare equally.
          let key = try decoder.decode(String.self, from: Data(bytes[start..<end]))
          let last = scopes.count - 1

          guard scopes[last].insert(key).inserted else {
            throw JSONCError("Duplicate configuration key: \(key).")
          }
        }
      default: break
      }

      index += 1
    }
  }

  private static func stripExtensions(_ data: Data) throws -> Data {
    var bytes = Array(data)
    var index = 0
    var inString = false
    var escaped = false
    var previous: UInt8?
    var trailingComma: Int?

    while index < bytes.count {
      let byte = bytes[index]

      if inString {
        if escaped {
          escaped = false
        } else if byte == 0x5C {
          escaped = true
        } else if byte == 0x22 {
          inString = false
        }

        index += 1
        continue
      }

      if byte == 0x2F, index + 1 < bytes.count {
        let next = bytes[index + 1]

        if next == 0x2F {
          while index < bytes.count, bytes[index] != 0x0A, bytes[index] != 0x0D {
            bytes[index] = 0x20
            index += 1
          }

          continue
        }

        if next == 0x2A {
          let start = index
          bytes[index] = 0x20
          bytes[index + 1] = 0x20
          index += 2

          var closed = false

          while index < bytes.count {
            if bytes[index] == 0x2A, index + 1 < bytes.count, bytes[index + 1] == 0x2F {
              bytes[index] = 0x20
              bytes[index + 1] = 0x20
              index += 2
              closed = true
              break
            }

            if bytes[index] != 0x0A, bytes[index] != 0x0D { bytes[index] = 0x20 }

            index += 1
          }

          guard closed else {
            throw JSONCError("Unterminated block comment at byte \(start + 1).")
          }

          continue
        }
      }

      if byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D {
        index += 1
        continue
      }

      if byte == 0x2C {
        // Do not turn missing values or repeated commas into valid JSON.
        guard let previous, ![0x5B, 0x7B, 0x3A, 0x2C].contains(previous) else {
          throw JSONCError("Unexpected comma at byte \(index + 1).")
        }

        trailingComma = index
      } else {
        if byte == 0x5D || byte == 0x7D, let trailingComma {
          bytes[trailingComma] = 0x20
        }

        trailingComma = nil
      }

      if byte == 0x22 { inString = true }

      previous = byte
      index += 1
    }

    return Data(bytes)
  }
}

/// A JSONC syntax or duplicate-key diagnostic.
public struct JSONCError: LocalizedError, Sendable {
  public var errorDescription: String? { message }

  private let message: String

  init(_ message: String) { self.message = message }
}
