import Spectre
import Conche


describe("a specification") {
  var specification = Specification(name: "Conche", version: "1.0.0")

  $0.it("has a name") {
    try equal(specification.name, "Conche")
  }

  $0.it("has a version") {
    try equal(specification.version, "1.0.0")
  }
}

