import Conche


describe("Dependency") {
  let dependency = Dependency(name: "Conche", requirements: ["> 1", "< 1.2"])

  $0.it("has a name") {
    try equal(dependency.name, "Conche")
  }

  $0.it("has has requirements") {
    try equal(dependency.requirements.description, "[\"> 1\", \"< 1.2\"]")
  }

  $0.it("has a description") {
    try equal(dependency.description, "Conche (> 1, < 1.2)")
  }
}

