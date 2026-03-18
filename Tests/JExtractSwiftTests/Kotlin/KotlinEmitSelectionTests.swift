import SwiftJavaConfigurationShared
import Testing

@Suite
struct KotlinEmitSelectionTests {
  @Test("selects kotlin-jvm emit")
  func selectsKotlinJvmEmit() throws {
    let decodedConfig = try readConfiguration(
      string:
        """
        {
          "swiftModule": "Example",
          "emit": "kotlin-jvm"
        }
        """,
      configPath: nil
    )
    let config = try #require(decodedConfig)

    #expect(config.emit == .kotlinJvm)
    #expect(config.effectiveEmit == .kotlinJvm)
  }
}
