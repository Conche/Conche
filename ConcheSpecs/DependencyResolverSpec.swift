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
      let specs = try resolve(depends("Cookie", ["1.0.0"]), sources: [source])
      try specs.hasSpecification("Cookie", "1.0.0")
      try expect(specs.count) == 1
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
        let specs = try resolve(depends("Car",["1.1.0"]), sources:[source])
        try specs.hasSpecification("Car", "1.1.0")
        try specs.hasSpecification("Engine", "1.1.0")
        try specs.hasSpecification("Wheel", "3.0.15")
        try specs.hasSpecification("Gasoline", "1.11.0")
        try expect(specs.count) == 4
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
        let specs = try resolve(depends("Car",["1.1.0"]), sources:[source])
        try specs.hasSpecification("Car", "1.1.0")
        try specs.hasSpecification("Engine", "1.1.0")
        try specs.hasSpecification("Wheel", "3.0.15")
        try specs.hasSpecification("Gasoline", "1.0.2")
        try expect(specs.count) == 4
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
        let specs = try resolve(depends("ChocolateChip",["0.1.1"]), sources:[source])
        try specs.hasSpecification("ChocolateChip", "0.1.1")
        try specs.hasSpecification("Cocoa", "1.0.5")
        try expect(specs.count) == 2
      }
    }

    $0.context("and explicitly requested") {
      $0.it("satisfies using prereleases") {
        let specs = try resolve(depends("ChocolateChip",["0.2.0"]), sources:[source])
        try specs.hasSpecification("ChocolateChip", "0.2.0")
        try specs.hasSpecification("Cocoa", "2.0.0-beta")
        try expect(specs.count) == 2
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
      try expect(
        try resolve(depends("Cookie", ["1.0.0"]), sources: [source])
      ).toThrow(DependencyResolverError.CircularDependency("Cookie", requiredBy: source.specifications))
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
