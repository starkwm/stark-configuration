import Foundation
import StarkConfiguration
import Testing

@Suite("JSONC")
struct JSONCTests {
  @Test func preservesStringsAndPositions() throws {
    let source = #"""
      { /* café */ "url": "https://example.com/*path*/", // comment
        "text": "quote: \" // literal", "slash": "\\", "unicode": "日本語", }
      """#

    let result = try JSONC.normalized(Data(source.utf8))
    let value = try JSONDecoder().decode([String: String].self, from: result)

    #expect(value["url"] == "https://example.com/*path*/")
    #expect(value["text"] == "quote: \" // literal")
    #expect(value["slash"] == "\\")
    #expect(value["unicode"] == "日本語")

    #expect(result.count == source.utf8.count)
    #expect(
      result.enumerated().filter { $0.element == 0x0A }.map(\.offset)
        == source.utf8.enumerated().filter { $0.element == 0x0A }.map(\.offset)
    )
  }

  @Test func stripsTrailingCommas() throws {
    let source = "{\"values\":[1, {\"nested\":[true,],}, /* end */\r\n],}// EOF"
    let normalized = try JSONC.normalized(Data(source.utf8))
    let expected = Data("{\"values\":[1, {\"nested\":[true ] }           \r\n] }      ".utf8)

    #expect(normalized == expected)
  }

  @Test(
    arguments: [
      "[,]", "{,}", "[1,,]", "{\"x\":,}", "[1,/* comment */,]",
      "[1/* comment */2]", "/* unfinished", "{} /* unfinished", "[1,] garbage",
    ]
  )
  func rejectsInvalidJSONC(source: String) {
    #expect(throws: (any Error).self) {
      _ = try JSONC.normalized(Data(source.utf8), rejectingDuplicateKeys: true)
    }
  }

  @Test func preservesJSON() throws {
    let data = Data(#"{"key":1,"key":2,"object":{},"array":[]}"#.utf8)

    #expect(try JSONC.normalized(data) == data)
  }
}

@Suite("Duplicate keys")
struct DuplicateKeyTests {
  @Test(arguments: [
    #"{"key":1,"key":2}"#,
    #"{"key":1,"\u006bey":2}"#,
    #"{"nested":[{"key":1,"key":2}]}"#,
    #"{"key":[{"key":1}],"key":2}"#,
  ])
  func rejectsDuplicates(source: String) {
    #expect(throws: JSONCError.self) {
      try JSONC.normalized(Data(source.utf8), rejectingDuplicateKeys: true)
    }
  }

  @Test(arguments: [
    #"[{"key":1},{"key":2}]"#,
    #"{"key":[{"key":1},[{"key":2}]],"other":{"key":3}}"#,
    #"{"]":[{"{":"}:\"\\","key":1}],"key":2}"#,
    "true", "6", "null", #""text""#,
  ])
  func allowsUniqueKeys(source: String) throws {
    try JSONC.rejectDuplicateKeys(Data(source.utf8))
  }

  @Test(arguments: ["}", "[", #"{"x":}"#, #"{"x":"unfinished}"#, "{} garbage"])
  func validatesBeforeScanning(source: String) {
    #expect(throws: (any Error).self) { try JSONC.rejectDuplicateKeys(Data(source.utf8)) }
  }
}
