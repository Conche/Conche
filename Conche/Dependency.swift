enum DependencyError : ErrorType {
  case InvalidOperator(String)
}

public struct Dependency : CustomStringConvertible {
  public let name: String
  public let requirements: [String]

  public init(name: String, requirements: [String]? = nil) {
    self.name = name
    self.requirements = requirements ?? []
  }

  public var description: String {
    if requirements.isEmpty {
      return name
    }

    let requires = requirements.joinWithSeparator(", ")
    return "\(name) (\(requires))"
  }

  public func satisfies(version: Version) throws -> Bool {
    return try requirements.map {
      try satisfies($0, version)
    }.filter { $0 == false }.first ?? true
  }

  private func satisfies(requirement: String, _ version: Version) throws -> Bool {
    let components = requirement.characters.split(2) { $0 == " " }.map(String.init)
    if components.count == 2 {
      let `operator` = components[0]
      let comparisonVersion = try Version(components[1])

      switch `operator` {
      case "=":
        return version == comparisonVersion
      case ">":
        return version > comparisonVersion
      case "<":
        return version < comparisonVersion
      case ">=":
        return version >= comparisonVersion
      case "<=":
        return version <= comparisonVersion
      case "~>":
        return version ~> comparisonVersion
      default:
        throw DependencyError.InvalidOperator(`operator`)
      }
    }

    let exactRequirement = try Version(requirement)
    return exactRequirement == version
  }
}

