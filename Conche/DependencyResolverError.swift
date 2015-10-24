public enum DependencyResolverError : ErrorType, Equatable, CustomStringConvertible {
  case NoSuchDependency(Dependency)
  case CircularDependency(DependencyGraph)
  case Conflict(String, requiredBy: [Dependency])

  public var description: String {
    switch self {
    case .NoSuchDependency(let dependency):
      return "Dependency '\(dependency)' not found."
    case .Conflict(let dependencyName, let requirements):
      return "Dependency '\(dependencyName)' requires conflicting versions from requirements: \(requirements)."
    case .CircularDependency(let graph):
      return "Dependency '\(graph.root.name)' resolved to a cycle using requirements: \(graph.flatten())"
    }
  }
}

/// Returns if to dependency resolver errors are identical
/// note: Circular dependencies do not correctly check the inner specifications
public func == (lhs: DependencyResolverError, rhs: DependencyResolverError) -> Bool {
  switch (lhs, rhs) {
  case let (.NoSuchDependency(lhsDependency), .NoSuchDependency(rhsDependency)):
    return lhsDependency == rhsDependency
  case let (.Conflict(lhsName, lhsRequirements), .Conflict(rhsName, rhsRequirements)):
    return lhsName == rhsName && lhsRequirements == rhsRequirements
  case let (.CircularDependency(lhsGraph), .CircularDependency(rhsGraph)):
    return lhsGraph ~= rhsGraph
  default:
    return false
  }
}
