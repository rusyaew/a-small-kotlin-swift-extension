import JExtractSwiftLib
import SwiftJavaConfigurationShared

func makeKotlinStubGenerator(
  _ input: String,
  swiftModuleName: String = "SwiftModule",
  javaPackage: String = "com.example.swift",
  outputDirectory: String = "/fake"
) throws -> KotlinJvmStubGenerator {
  var config = Configuration()
  config.swiftModule = swiftModuleName
  config.javaPackage = javaPackage
  config.outputJavaDirectory = outputDirectory
  config.outputSwiftDirectory = "/unused"

  let translator = Swift2JavaTranslator(config: config)
  translator.log.logLevel = .error
  try translator.analyze(path: "/fake/Fake.swift", text: input)

  return KotlinJvmStubGenerator(
    config: config,
    translator: translator,
    kotlinPackage: javaPackage,
    kotlinOutputDirectory: outputDirectory
  )
}

func composeKotlinStubSource(
  _ input: String,
  swiftModuleName: String = "SwiftModule",
  javaPackage: String = "com.example.swift"
) throws -> String {
  let generator = try makeKotlinStubGenerator(
    input,
    swiftModuleName: swiftModuleName,
    javaPackage: javaPackage
  )
  let functions = generator.collectStubFunctions()
  return generator.composeStubModuleSource(
    packageName: javaPackage,
    moduleName: swiftModuleName,
    functions: functions
  )
}
