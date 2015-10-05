enum DependencyResolverError : ErrorType, CustomStringConvertible {
  case NoSuchDependency(Dependency, requiredBy:[Specification])

  var description:String {
    switch self {
    case .NoSuchDependency(let dependency, let requiredBy):
      return "Dependency \(dependency) not found."
    }
  }
}

// EXTREMELY naive MVP resolver (no actual version matching, only latest, ++optimistic).
public class DependencyResolver {
  let specification:Specification
  let sources:[SourceType]

  public init(specification:Specification, sources:[SourceType]) {
    self.specification = specification
    self.sources = sources
  }

  public func resolve() throws -> [Specification] {
    // TODO, perform topological sort
    return try resolve(specification)
  }

  // @segiddins, do NOT enter here.
  private func resolve(specification:Specification) throws -> [Specification] {
    let dependencies = try specification.dependencies.map { try resolve($0) }
    return dependencies.reduce([], combine: +) + [specification]
  }

  private func resolve(dependency:Dependency) throws -> [Specification] {
    // TODO, handle circular dependencies instead of infinitely loop :D

    if dependency.name.characters.contains("/") {
      // TODO Subspecs are not supported
      throw DependencyResolverError.NoSuchDependency(dependency, requiredBy: [])
    }

    let specifications = sources.map { $0.search(dependency) }.reduce([], combine: +)

    if let specification = specifications.last {
      let specifications = try resolve(specification)
      return specifications + [specification]
    }

    throw DependencyResolverError.NoSuchDependency(dependency, requiredBy: [])
  }
}

