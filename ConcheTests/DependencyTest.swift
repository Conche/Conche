import Spectre
import Conche

func satisfies(requirements: [String], _ version: Version) throws {
  let dependency = try Dependency(name: "", requirements: requirements)
  try equal(dependency.satisfies(version), true)
}

func doesntSatisfy(requirements: [String], _ version: Version) throws {
  let dependency = try Dependency(name: "", requirements: requirements)
  try equal(dependency.satisfies(version), false)
}

describe("Dependency") {
  let dependency = try! Dependency(name: "Conche", requirements: ["> 1", "< 1.2"])

  $0.it("has a name") {
    try equal(dependency.name, "Conche")
  }

  $0.it("has has requirements") {
    try equal(dependency.requirements.description, "[> 1, < 1.2]")
  }

  $0.it("has a description") {
    try equal(dependency.description, "Conche (> 1, < 1.2)")
  }

  $0.it("is hashable") {
    let items = [dependency: 3]
    try equal(items[dependency], 3)
  }

  $0.it("equals a dependency with the same name and requirements") {
    let dep = try Dependency(name: "Conche", requirements: ["> 1", "< 1.2"])
    try equal(dependency, dep)
  }

  $0.it("does not equal a dependency with the same requirements and different name") {
    let dep = try Dependency(name: "SPECTRE", requirements: ["> 1", "< 1.2"])
    try notEqual(dependency, dep)
  }

  $0.it("does not equal a dependency with the same name and different requirements") {
    let dep = try Dependency(name: "Conche", requirements: ["< 1.2"])
    try notEqual(dependency, dep)
  }

  $0.context("when satisfying a version") {
    $0.it("satisfies without requirements") {
      try satisfies([], Version(major: 1, minor: 2, patch: 3))
    }

    $0.it("satisfies an exact match") {
      try satisfies(["1.2.3"], Version(major: 1, minor: 2, patch: 3))
      try doesntSatisfy(["1.2.4"], Version(major: 1, minor: 2, patch: 3))
    }

    $0.it("satisfies > operator match") {
      try satisfies(["= 1.2.3"], Version(major: 1, minor: 2, patch: 3))
      try doesntSatisfy(["= 1.2.4"], Version(major: 1, minor: 2, patch: 3))
    }

    $0.it("satisfies > operator match") {
      try satisfies(["> 1.2"], Version(major: 1, minor: 2, patch: 3))
      try doesntSatisfy(["> 1.2"], Version(major: 1, minor: 1, patch: 3))
    }

    $0.it("satisfies < operator match") {
      try satisfies(["< 1.3"], Version(major: 1, minor: 2, patch: 3))
      try doesntSatisfy(["< 1.2"], Version(major: 1, minor: 2, patch: 3))
    }

    $0.it("satisfies >= operator match") {
      try satisfies([">= 1.2.3"], Version(major: 1, minor: 2, patch: 3))
      try doesntSatisfy([">= 1.2"], Version(major: 1, minor: 1, patch: 0))
    }

    $0.it("satisfies <= operator match") {
      try satisfies(["<= 1.2.3"], Version(major: 1, minor: 2, patch: 3))
      try doesntSatisfy(["<= 1.0"], Version(major: 1, minor: 1, patch: 0))
    }

    $0.it("satisfies ~> operator match") {
      try satisfies(["~> 1.2.3"], Version(major: 1, minor: 2, patch: 3))
      try doesntSatisfy(["~> 1.2"], Version(major: 1, minor: 1, patch: 0))
    }
  }
}

