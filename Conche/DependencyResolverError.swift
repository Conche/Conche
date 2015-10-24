public enum DependencyResolverError : ErrorType, Equatable, CustomStringConvertible {
  case CircularDependency(String, requiredBy: [Dependency])
  case Conflict(String, requiredBy: [Dependency])
  case NoSuchDependency(Dependency)

  public var description: String {
    switch self {
    case .CircularDependency(let dependencyName, let requirements):
      return "Dependency '\(dependencyName)' could not be resolved due to circular references between: \(requirements)."
    case .Conflict(let dependencyName, let requirements):
      return "Dependency '\(dependencyName)' requires conflicting versions from requirements: \(requirements)."
    case .NoSuchDependency(let dependency):
      return "Dependency '\(dependency)' not found."
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
  case let (.CircularDependency(lhsName, lhsRequirements), .CircularDependency(rhsName, rhsRequirements)):
    return lhsName == rhsName && lhsRequirements == rhsRequirements
  default:
    return false
  }
}
