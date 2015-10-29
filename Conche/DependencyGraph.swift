public struct DependencyGraph {
  public let root: Specification
  let dependencies: [DependencyGraph]

  public init(root: Specification, dependencies: [DependencyGraph]) {
    self.root = root
    self.dependencies = dependencies
  }

  /// Flatten the dependency graph into the root specifications
  public func flatten() -> [Specification] {
    let dependentSpecs = dependencies.map { $0.flatten() }
    return ([root] + dependentSpecs.reduce([], combine: +)).uniq()
  }

  /// Check for a reference to the root specification in the dependencies
  func hasCircularReference() -> Bool {
    return detectDuplicate([root.name])
  }

  func detectDuplicate(specificationNames: [String]) -> Bool {
    return dependencies.filter {
      return specificationNames.contains($0.root.name) ||
             $0.detectDuplicate(specificationNames + [$0.root.name])
    }.count > 0
  }
}

extension DependencyGraph: CustomStringConvertible {
  public var description: String {
    return "\(root): \(dependencies)"
  }
}

infix operator ~= { associativity left precedence 130 }

/// Compute functional equivalence within an acceptable degree of error
public func ~= (lhs: DependencyGraph, rhs: DependencyGraph) -> Bool {
  if lhs.root.name == rhs.root.name &&
     lhs.root.version == rhs.root.version &&
     lhs.dependencies.count == rhs.dependencies.count {
    for (index, graph) in lhs.dependencies.enumerate() {
      if !(graph ~= rhs.dependencies[index]) {
        return false
      }
    }

    return true
  }

  return false
}

extension CollectionType where Generator.Element == DependencyGraph {
  func uniq() -> [Generator.Element] {
    var seen: [String: Bool] = [:]
    return filter {
      let key = "\($0.root.name) \($0.root.version)"
      return seen.updateValue(true, forKey: key) == nil
    }
  }

  /// Sorts graphs by name and version, lowest first
  func sort() -> [Generator.Element] {
    return sort { $0.root.name < $1.root.name }
  }
}
