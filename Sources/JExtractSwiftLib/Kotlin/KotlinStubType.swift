package enum KotlinStubType: Equatable {
  case int
  case boolean
  case double
  case string
  case unit

  var kotlinSpelling: String {
    switch self {
    case .int:
      "Int"
    case .boolean:
      "Boolean"
    case .double:
      "Double"
    case .string:
      "String"
    case .unit:
      "Unit"
    }
  }
}
