import Foundation
import Spectre
import Conche


describe("Specification") {
  let version = Version(major: 1, minor: 0, patch: 0)
  var specification = Specification(name: "Conche", version: version)

  $0.it("has a name") {
    try expect(specification.name) == "Conche"
  }

  $0.it("has a version") {
    try expect(specification.version) == version
  }

  $0.it("has a description") {
    try expect(specification.description) == "Conche (1.0.0)"
  }

  $0.context("loading from a representation") {
    $0.it("loads with a name and version") {
      let specification = try Specification(representation: [
        "name": "Conche",
        "version": "1.0.0",
      ])

      try expect(specification.name) == "Conche"
      try expect(specification.version) == version
    }

    $0.it("errors without a name") {
      try expect(try Specification(representation: [:])).toThrow()
    }

    $0.it("errors when name and version are incorrect type") {
      try expect(
        try Specification(representation: [
          "name": 0,
          "version": 1.0,
        ])
      ).toThrow()
    }
  }
}
