import Spectre
import Conche

extension CollectionType where Generator.Element == Specification {
  func hasSpecification(name:String, _ version:String) throws {
    let items = filter { $0.name == name && $0.version.description == version }
    if items.isEmpty {
      let descriptions = items.map { $0.description }
      throw failure("Collection did not contain \(name)-\(version): \(descriptions)")
    }
  }
}

infix operator ~= { associativity left precedence 130 }
func ~= <E: ExpectationType where E.ValueType == DependencyGraph>(lhs: E, rhs: E.ValueType) throws {
  if let value = try lhs.expression() {
    guard value ~= rhs else {
      throw lhs.failure("\(value) is not equivalent to \(rhs)")
    }
  } else {
    throw lhs.failure("given value is nil")
  }
}

func spec(name:String, _ version:String, _ dependencies:[Dependency]? = nil) -> Specification {
  return Specification(name:name, version:try! Version(version)) {
    dependencies?.forEach($0.dependency)
  }
}

func depends(name:String, _ requirements:[String]? = nil) -> Dependency {
  return try! Dependency(name:name, requirements:requirements)
}

class InMemorySource : SourceType {
  let specifications:[Specification]

  init(specifications:[Specification]) {
    self.specifications = specifications
  }

  func search(dependency:Dependency) -> [Specification] {
    return specifications.filter {
      $0.name == dependency.name && dependency.satisfies($0.version)
    }
  }

  func update() throws {}
}

describe("resolve()") {
  $0.context("A specification has no dependencies") {
    let source = InMemorySource(specifications: [
      spec("Cookie", "1.0.0"),
      spec("Cookie", "1.1.0"),
    ])

    $0.it("resolves the single specification") {
      let graph = try resolve(depends("Cookie", ["1.0.0"]), sources: [source], dependencies: [])
      try expect(graph) ~= DependencyGraph(root: source.specifications[0], dependencies: [])
    }
  }

  $0.context("A specification has chained dependencies") {

    $0.context("requiring the latest available versions") {
      let source = InMemorySource(specifications:[
        spec("Car", "1.1.0", [depends("Wheel"), depends("Engine")]),
        spec("Car", "1.0.0", [depends("Wheel"), depends("Engine")]),
        spec("Engine", "1.1.0", [depends("Gasoline")]),
        spec("Wheel", "3.0.15"),
        spec("Gasoline", "1.0.2"),
        spec("Gasoline", "1.11.0")
      ])

      $0.it("resolves the set of specifications") {
        let graph = try resolve(depends("Car",["1.1.0"]), sources:[source], dependencies: [])
        try expect(graph) ~= DependencyGraph(root: spec("Car", "1.1.0"), dependencies: [
          DependencyGraph(root: spec("Engine", "1.1.0"), dependencies: [
            DependencyGraph(root: spec("Gasoline", "1.11.0"), dependencies: [])
          ]),
          DependencyGraph(root: spec("Wheel", "3.0.15"), dependencies: [])
        ])
      }
    }

    $0.context("requiring versions older than latest") {
      let source = InMemorySource(specifications:[
        spec("Car", "1.1.0", [depends("Wheel"), depends("Engine"), depends("Gasoline",["1.0.2"])]),
        spec("Car", "1.0.0", [depends("Wheel"), depends("Engine")]),
        spec("Engine", "1.1.0", [depends("Gasoline")]),
        spec("Wheel", "3.0.15"),
        spec("Gasoline", "1.0.2"),
        spec("Gasoline", "1.0.3"),
        spec("Gasoline", "1.11.0")
      ])

      $0.it("resolves the set of specifications") {
        let graph = try resolve(depends("Car",["1.1.0"]), sources:[source], dependencies: [])
        try expect(graph) ~= DependencyGraph(root: spec("Car", "1.1.0"), dependencies: [
          DependencyGraph(root: spec("Engine", "1.1.0"), dependencies: [
            DependencyGraph(root: spec("Gasoline", "1.0.2"), dependencies: [])
          ]),
          DependencyGraph(root: spec("Gasoline", "1.0.2"), dependencies: []),
          DependencyGraph(root: spec("Wheel", "3.0.15"), dependencies: [])
        ])
      }
    }
  }

  $0.context("Satisfactory dependency version is pre-release") {
    let source = InMemorySource(specifications:[
      spec("Cookie", "1.0.0"),
      spec("ChocolateChip", "0.1.1", [depends("Cocoa")]),
      spec("ChocolateChip", "0.2.0", [depends("Cocoa", ["> 1.9.0-beta"])]),
      spec("Cocoa", "1.0.4"),
      spec("Cocoa", "1.0.5"),
      spec("Cocoa", "2.0.0-beta")
    ])

    $0.context("and not explicitly requested") {
      $0.it("ignores prereleases") {
        let graph = try resolve(depends("ChocolateChip",["0.1.1"]), sources:[source], dependencies: [])
        try expect(graph) ~= DependencyGraph(root: spec("ChocolateChip", "0.1.1"), dependencies: [
          DependencyGraph(root: spec("Cocoa", "1.0.5"), dependencies: [])
        ])
      }
    }

    $0.context("and explicitly requested") {
      $0.it("satisfies using prereleases") {
        let graph = try resolve(depends("ChocolateChip",["0.2.0"]), sources:[source], dependencies: [])
        try expect(graph) ~= DependencyGraph(root: spec("ChocolateChip", "0.2.0"), dependencies: [
          DependencyGraph(root: spec("Cocoa", "2.0.0-beta"), dependencies: [])
        ])
      }
    }
  }

  $0.context("The dependencies require two versions of the same dependency") {
    let source = InMemorySource(specifications: [
      spec("Cookie", "1.0.0"),
      spec("Cookie", "1.1.0"),
      spec("Milk", "2.0.0",
        [depends("Cookie", ["> 1.0.0"])]),
      spec("Milk", "2.1.0",
        [depends("Cookie", ["1.1.0"])]),
      spec("ChocolateMilk", "1.0.0",
        [depends("Cookie", ["1.0.0"]), depends("Milk")])
    ])

    $0.it("throws a 'conflict' error") {
      try expect(
        try resolve(depends("ChocolateMilk", ["1.0.0"]), sources: [source])
      ).toThrow(DependencyResolverError.Conflict("Cookie", requiredBy: [
        depends("Cookie", ["1.0.0"]),
        depends("Milk"),
        depends("Cookie", ["> 1.0.0"])
      ]))
    }
  }

  $0.context("The dependencies resolve to a cycle") {
    let source = InMemorySource(specifications:[
      spec("Cookie", "1.0.0", [depends("ChocolateChip")]),
      spec("Cookie", "1.1.0"),
      spec("ChocolateChip", "1.1.0",[depends("Milk")]),
      spec("Milk", "2.1.5", [depends("Cookie")])
    ])

    $0.it("throws a 'circular reference' error") {
      let graph = DependencyGraph(root: spec("Cookie", "1.0.0"), dependencies: [
        DependencyGraph(root: spec("ChocolateChip", "1.1.0"), dependencies: [
          DependencyGraph(root: spec("Milk", "2.1.5"), dependencies: [
            DependencyGraph(root: spec("Cookie", "1.1.0"), dependencies: [])
          ])
        ])
      ])
      try expect(
        try resolve(depends("Cookie", ["1.0.0"]), sources: [source])
      ).toThrow(DependencyResolverError.CircularDependency(graph))
    }
  }

  $0.context("Dependecies with the same name and version are in multiple sources") {
    let source1 = InMemorySource(specifications: [spec("Cookie","1.0.0")])
    let source2 = InMemorySource(specifications: [spec("Cookie","1.0.0")])

    $0.it("resolves to a single specification") {
      let specs = try resolve(depends("Cookie",["1.0.0"]), sources:[source1, source2])
      try specs.hasSpecification("Cookie", "1.0.0")
      try expect(specs.count) == 1
    }
  }

  $0.context("The dependencies require a version not available in sources") {
    let source = InMemorySource(specifications: [spec("Cookie","1.0.0")])

    $0.it("throws a 'no such dependency' error") {
      let dependency = depends("Cookie", ["> 1.0.0"])
      try expect(
        try resolve(dependency, sources: [source])
      ).toThrow(DependencyResolverError.NoSuchDependency(dependency))
    }
  }

  $0.context("The dependencies require a dependency not available in sources") {
    let source = InMemorySource(specifications: [spec("Cookie","1.0.0")])

    $0.it("throws a 'no such dependency' error") {
      let dependency = depends("Biscuit", ["1.0.0"])
      try expect(
        try resolve(dependency, sources: [source])
      ).toThrow(DependencyResolverError.NoSuchDependency(dependency))
    }
  }
}
