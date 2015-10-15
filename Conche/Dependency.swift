enum DependencyError : ErrorType {
  case InvalidOperator(String)
}

public enum RequirementOperator : String, CustomStringConvertible {
  case Equal = "="
  case Optimistic = "~>"
  case LessThan = "<"
  case LessThanEqual = "<="
  case MoreThan = ">"
  case MoreThanEqual = ">="

  public var description: String {
    return rawValue
  }

  func satisfies(lhs: Version, _ rhs: Version) -> Bool {
    switch self {
    case .Equal:
      return lhs == rhs
    case .Optimistic:
      return lhs ~> rhs
    case .LessThan:
      return lhs < rhs
    case .LessThanEqual:
      return lhs <= rhs
    case .MoreThan:
      return lhs > rhs
    case .MoreThanEqual:
      return lhs >= rhs
    }
  }
}

public struct Requirement : CustomStringConvertible, Equatable {
  public let version: Version
  public let `operator`: RequirementOperator

  init(_ value: String) throws {
    let components = value.characters.split(2) { $0 == " " }.map(String.init)
    if components.count == 2 {
      if let `operator` = RequirementOperator(rawValue: components[0]) {
        self.`operator` = `operator`
      } else {
        throw DependencyError.InvalidOperator(components[0])
      }
      version = try Version(components[1])
    } else {
      version = try Version(value)
      `operator` = .Equal
    }
  }

  public var description: String {
    return "\(`operator`) \(version)"
  }

  func satisfies(version: Version) -> Bool {
    return `operator`.satisfies(version, self.version)
  }
}

public struct Dependency : CustomStringConvertible, Hashable, Equatable {
  public let name: String
  public let requirements: [Requirement]

  public init(name: String, requirements: [Requirement]? = nil) {
    self.name = name
    self.requirements = requirements ?? []
  }

  public init(name: String, requirements: [String]? = nil) throws {
    self.name = name
    self.requirements = try requirements?.map { try Requirement($0) } ?? []
  }

  public var description: String {
    if requirements.isEmpty {
      return name
    }

    let requires = requirements.map { $0.description }.joinWithSeparator(", ")
    return "\(name) (\(requires))"
  }

  public func satisfies(version: Version) -> Bool {
    return requirements.map {
      $0.satisfies(version)
    }.filter { $0 == false }.first ?? true
  }

  public var hashValue: Int {
    return description.hashValue
  }
}

public func ==(lhs: Dependency, rhs: Dependency) -> Bool {
  return lhs.name == rhs.name && lhs.requirements == rhs.requirements
}

public func ==(lhs: Requirement, rhs: Requirement) -> Bool {
  return lhs.version == rhs.version && lhs.`operator` == rhs.`operator`
}

