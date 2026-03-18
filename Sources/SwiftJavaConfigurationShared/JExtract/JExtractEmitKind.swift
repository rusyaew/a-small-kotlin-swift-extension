public enum JExtractEmitKind: String, Sendable, Codable {
  /// Emit Java sources using the existing generators
  case java

  /// Emit top-level Kotlin/JVM stub sources
  case kotlinJvm = "kotlin-jvm"

  public static var `default`: JExtractEmitKind {
    .java
  }
}
