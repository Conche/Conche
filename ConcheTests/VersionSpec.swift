import Spectre
import Conche


describe("Version") {
  let version = Version(major: 1, minor: 0, patch: 0)

  $0.it("has a major") {
    try equal(version.major, 1)
  }

  $0.it("has a minor") {
    try equal(version.minor, 0)
  }

  $0.it("has a patch") {
    try equal(version.patch, 0)
  }

  $0.it("can be converted to a string") {
    try equal(version.description, "1.0.0")
  }

  $0.it("is equal to version with the same major, minor and patch") {
    try equal(version, Version(major: 1, minor: 0, patch: 0))
  }

  $0.it("is not equal to version with a different major, minor and patch") {
    try notEqual(version, Version(major: 2, minor: 0, patch: 0))
    try notEqual(version, Version(major: 1, minor: 1, patch: 0))
    try notEqual(version, Version(major: 1, minor: 0, patch: 1))
  }

  $0.describe("when parsing a string") {
    $0.it("parses the major, minor and patch version") {
      let version = try Version("1.2.3")

      try equal(version.major, 1)
      try equal(version.minor, 2)
      try equal(version.patch, 3)
    }
  }
}

