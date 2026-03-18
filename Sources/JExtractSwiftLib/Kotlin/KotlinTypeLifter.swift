enum KotlinTypeLifter {
  static func liftSupportedType(_ swiftType: SwiftType) -> KotlinStubType? {
    if swiftType.isVoid {
      return .unit
    }

    switch swiftType.asNominalTypeDeclaration?.knownTypeKind {
    case .int, .int32:
      return .int
    case .bool:
      return .boolean
    case .double:
      return .double
    case .string:
      return .string
    case .void:
      return .unit
    default:
      return nil
    }
  }
}
