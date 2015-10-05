public struct Dependency : CustomStringConvertible {
  public let name:String
  public let requirements:[String]

  init(name:String, requirements:[String]) {
    self.name = name
    self.requirements = requirements
  }

  public var description:String {
    if requirements.isEmpty {
      return name
    }

    let x = requirements.joinWithSeparator(", ")
    return "\(name) (\(x))"
  }
}

