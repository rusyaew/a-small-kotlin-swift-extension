import Testing

@Suite
struct KotlinStubSkipTests {
  @Test("records skipped declarations as comments")
  func recordsSkippedDeclarations() throws {
    let output = try composeKotlinStubSource(
      """
      public func greet(name: String) -> String { name }
      public func maybeName(flag: Bool) -> String? { nil }
      public func update(value: inout Int) {}
      public func later() async {}
      public func risky() throws {}
      public func identity<T>(_ value: T) -> T { value }
      """
    )

    #expect(output.contains("fun greet(name: String): String = TODO(\"Not implemented\")"))
    #expect(!output.contains("fun maybeName("))
    #expect(!output.contains("fun update("))
    #expect(!output.contains("fun later("))
    #expect(!output.contains("fun risky("))
    #expect(!output.contains("fun identity("))
    #expect(output.contains("// Skipped declarations:"))
    #expect(output.contains("// - maybeName: [out of scope] return type 'String?' not supported"))
    #expect(output.contains("// - update: [out of scope] convention 'inout' not supported at 'value'"))
    #expect(output.contains("// - later: [out of scope] effects [async]"))
    #expect(output.contains("// - risky: [out of scope] effects [throws]"))
    #expect(output.contains("// - identity: [out of scope] input type 'T' not supported at 'value'"))
  }
}
