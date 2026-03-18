package struct KotlinStubFunction: Equatable {
  let name: String
  let parameters: [KotlinStubParameter]
  let resultType: KotlinStubType
}

package struct KotlinStubParameter: Equatable {
  let name: String
  let type: KotlinStubType
}

package struct KotlinSkippedFunction: Equatable {
  let swiftName: String
  let reason: String
}
