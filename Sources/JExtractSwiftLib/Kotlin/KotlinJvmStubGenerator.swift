import Foundation
import SwiftJavaConfigurationShared

// Error type for SwiftTypes/SwiftParameter.swift
private enum StubProjectionFailure: Error, CustomStringConvertible {
  case unsupportedConvention(parameter: String, convention: SwiftParameterConvention)
  case unsupportedParameterType(parameter: String, typeDescription: String)
  case unsupportedResultType(String)

  var description: String {
    switch self {
    case .unsupportedConvention(let parameter, let convention):
      return "[out of scope] convention '\(convention)' not supported at '\(parameter)'"
    case .unsupportedParameterType(let parameter, let typeDescription):
      return "[out of scope] input type '\(typeDescription)' not supported at '\(parameter)'"
    case .unsupportedResultType(let typeDescription):
      return "[out of scope] return type '\(typeDescription)' not supported"
    }
  }
}

// We fork JExtractSwiftLib/FFM/FFMSwift2JavaGenerator.swift but don't do lowering
package final class KotlinJvmStubGenerator {
  let log: Logger
  let config: Configuration
  let analysis: AnalysisResult
  let swiftModuleName: String
  let kotlinPackage: String
  let kotlinOutputDirectory: String

  package private(set) var skippedFunctions: [KotlinSkippedFunction] = []

  package init(
    config: Configuration,
    translator: Swift2JavaTranslator,
    kotlinPackage: String,
    kotlinOutputDirectory: String
  ) {
    self.log = Logger(label: "kotlin-jvm", logLevel: translator.log.logLevel)
    self.config = config
    self.analysis = translator.result
    self.swiftModuleName = translator.swiftModuleName
    self.kotlinPackage = kotlinPackage // [todo] possibly include both kotlinPackage and javaPackage
    self.kotlinOutputDirectory = kotlinOutputDirectory
  }

  package func emitStubs() throws {
    skippedFunctions.removeAll()
    let functions = collectStubFunctions()
    let contents = composeStubModuleSource(
      packageName: kotlinPackage,
      moduleName: swiftModuleName,
      functions: functions
    )

    try writeStubModuleFile(
      outputDirectory: kotlinOutputDirectory,
      packageName: kotlinPackage,
      moduleName: swiftModuleName,
      contents: contents
    )

    log.info("kotlin-jvm: wrote stub source for module '\(swiftModuleName)' to \(kotlinOutputDirectory)")
  }

  package func collectStubFunctions() -> [KotlinStubFunction] {
    var functions: [KotlinStubFunction] = []
    functions.reserveCapacity(analysis.importedGlobalFuncs.count)

    for decl in analysis.importedGlobalFuncs {
      guard !decl.hasParent else {
        warnAndSkip(decl, because: "[out of scope] only top-level")
        continue
      }

      let effects = decl.functionSignature.effectSpecifiers
      guard effects.isEmpty else {
        let effectList = effects.map(String.init(describing:)).joined(separator: ", ")
        warnAndSkip(decl, because: "[out of scope] effects [\(effectList)]")
        continue
      }

      switch projectStubFunction(from: decl) {
      case .success(let function):
        functions.append(function)
      case .failure(let issue):
        warnAndSkip(decl, because: issue.description)
      }
    }

    return functions
  }

  package func composeStubModuleSource(
    packageName: String,
    moduleName: String,
    functions: [KotlinStubFunction]
  ) -> String {
    CodePrinter.toString { printer in
      KotlinModuleStubPrinter(skippedFunctions: skippedFunctions)
        .printModule(&printer, packageName: packageName, moduleName: moduleName, functions: functions)
    }
  }

  package func writeStubModuleFile(
    outputDirectory: String,
    packageName: String,
    moduleName: String,
    contents: String
  ) throws {
    let packagePath = packageName.replacingOccurrences(of: ".", with: PATH_SEPARATOR)
    var outputURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
    if !packagePath.isEmpty {
      outputURL.appendPathComponent(packagePath, isDirectory: true)
    }

    try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

    let fileURL = outputURL.appendingPathComponent("\(moduleName).kt", isDirectory: false)
    try contents.write(to: fileURL, atomically: true, encoding: .utf8)
  }

  package func warnAndSkip(_ decl: ImportedFunc, because reason: String) {
    log.warning("kotlin-jvm: not emitting '\(decl.displayName)' \(reason)")
    skippedFunctions.append(.init(swiftName: decl.displayName, reason: reason))
  }

  // We do similar to FFM/FFMSwift2JavaGenerator+JavaTranslation.swift
  // (e.g. parameter naming, passes), but integrate Error and Result types for more
  // idiomatic work. Notably, JNI uses a different "arg\(idx)" convention
  private func projectStubFunction(from decl: ImportedFunc) -> Result<KotlinStubFunction, StubProjectionFailure> {
    var parameters: [KotlinStubParameter] = []
    parameters.reserveCapacity(decl.functionSignature.parameters.count)

    for (idx, swiftParam) in decl.functionSignature.parameters.enumerated() {
      let parameterName = swiftParam.parameterName ?? "_\(idx)"

      guard swiftParam.convention == .byValue else {
        return .failure(.unsupportedConvention(parameter: parameterName, convention: swiftParam.convention))
      }

      guard let projectedType = KotlinTypeLifter.liftSupportedType(swiftParam.type) else {
        return .failure(
          .unsupportedParameterType(
            parameter: parameterName,
            typeDescription: String(describing: swiftParam.type)
          )
        )
      }

      parameters.append(
        KotlinStubParameter(
          name: parameterName,
          type: projectedType
        )
      )
    }

    guard let resultType = KotlinTypeLifter.liftSupportedType(decl.functionSignature.result.type) else {
      return .failure(.unsupportedResultType(String(describing: decl.functionSignature.result.type)))
    }

    return .success(.init(name: decl.name, parameters: parameters, resultType: resultType))
  }
}
