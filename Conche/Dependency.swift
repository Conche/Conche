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
}

