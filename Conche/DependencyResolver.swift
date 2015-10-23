public enum DependencyResolverError : ErrorType, Equatable, CustomStringConvertible {
  case NoSuchDependency(Dependency)
  case CircularDependency(String, requiredBy: [Specification])
  case Conflict(String, requiredBy: [Dependency])

  public var description: String {
    switch self {
    case .NoSuchDependency(let dependency):
      return "Dependency '\(dependency)' not found."
    case .Conflict(let dependencyName, let requirements):
      return "Dependency '\(dependencyName)' requires conflicting versions from requirements: \(requirements)."
    case .CircularDependency(let dependencyName, let requirements):
      return "Dependency '\(dependencyName)' resolved to a cycle using requirements: \(requirements)"
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
  case let (.CircularDependency(lhsName, lhsSpecifications), .CircularDependency(rhsName, rhsSpecifications)):
    return lhsName == rhsName && lhsSpecifications.count == rhsSpecifications.count
  default:
    return false
  }
}

func resolveTestDependencies(testSpecification: TestSpecification?, sources: [SourceType]) throws -> [Specification] {
  let testDependencies = try testSpecification?.dependencies.map { try resolve($0, sources: sources) } ?? []
  return testDependencies.reduce([], combine: +)
}

/// Resolves a dependency with the given sources and returns
/// the collection of resolved specifications
public func resolve(dependency: Dependency, sources: [SourceType]) throws -> [Specification] {
  return try resolve(dependency, sources: sources, dependencies: [])
}

/// Resolve a dependency with the given sources, iteratively
/// adding all known dependencies from previous resolutions
/// in the dependency tree, returning the collection of resolved
/// specifications
private func resolve(dependency: Dependency, sources: [SourceType], dependencies: [Dependency]) throws -> [Specification] {
  var specifications = search(dependency.combine(dependencies.filter { $0.name == dependency.name }), sources: sources)
  while let specification = specifications.popFirst() {
    do {
      let resolution = try [specification] + specification.dependencies.map {
        try resolve($0, sources: sources, dependencies: dependencies + specification.dependencies)
      }.reduce([], combine: +).uniq()
      if let duplicate = resolution.detectDuplicate() {
        throw DependencyResolverError.CircularDependency(duplicate.name, requiredBy: resolution)
      }
      return resolution
    } catch let error as DependencyResolverError {
      if specifications.isEmpty {
        throw error
      }
    }
  }
  throw searchForConflict(dependency, sources: sources, dependencies: dependencies)
}

/// Searches available sources for dependencies, filtering out
/// pre-release versions if not explicitly requested
private func search(dependency: Dependency, sources: [SourceType]) -> ArraySlice<Specification> {
  var specifications = sources.map { $0.search(dependency) }.reduce([], combine: +).sort()
  if !dependency.usePreRelease() {
    specifications = specifications.removePreReleases()
  }
  return specifications[0..<specifications.endIndex]
}

/// Search available sources for dependencies, which are used
/// to correctly identify a pre-existing issue. If any found,
/// returns a conflict, otherwise 'no such dependency'.
private func searchForConflict(dependency: Dependency, sources: [SourceType], dependencies: [Dependency]) -> DependencyResolverError {
  let incompatible = search(dependency, sources: sources)
  if incompatible.count > 0 {
    return DependencyResolverError.Conflict(dependency.name, requiredBy: dependencies)
  }
  return DependencyResolverError.NoSuchDependency(dependency)
}

extension CollectionType where Generator.Element == Specification {
  /// Filters specifications removing pre-release versions
  func removePreReleases() -> [Generator.Element] {
    return filter { $0.version.prerelease == nil }
  }

  func uniq() -> [Generator.Element] {
    var seen: [String: Bool] = [:]
    return filter { seen.updateValue(true, forKey: $0.description) == nil }
  }

  /// Iterates over the specifications returning the first
  /// duplicated specification by name
  func detectDuplicate() -> Generator.Element? {
    var seen: [String] = []
    for element in self {
      if seen.contains(element.name) {
        return element
      }
      seen.append(element.name)
    }
    return nil
  }

  /// Sorts specifications by name and version
  func sort() -> [Generator.Element] {
    return sort { $0.name >= $1.name && $0.version >= $1.version }
  }
}

extension Dependency {

  /// Creates a dependency using the name and exact version of a
  /// specification
  init(specification: Specification) throws {
    self.name = specification.name
    self.requirements = try [Requirement(specification.version.description)] ?? []
  }

  func combine(dependencies: [Dependency]) -> Dependency {
    let reqs = dependencies.map { $0.requirements }.reduce(requirements, combine: +)
    return Dependency(name: name, requirements: reqs)
  }

  /// Flag to determine whether to use pre-release versions of
  /// specifications
  func usePreRelease() -> Bool {
    return requirements.contains { $0.version.prerelease != nil }
  }

  /// returns true if a specification cannot satisfy the dependency
  func incompatible(specification: Specification) -> Bool {
    return !satisfies(specification.version) || (!usePreRelease() && specification.version.prerelease != nil)
  }
}

