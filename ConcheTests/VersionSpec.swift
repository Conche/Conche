import Spectre
import Conche


describe("Version") {
  let version = Version(major: 1, minor: 2, patch: 3, prerelease: "beta.1")

  $0.it("has a major") {
    try equal(version.major, 1)
  }

  $0.it("has a minor") {
    try equal(version.minor, 2)
  }

  $0.it("has a patch") {
    try equal(version.patch, 3)
  }

  $0.it("has a prerelease") {
    try equal(version.prerelease, "beta.1")
  }

  $0.it("can be converted to a string") {
    try equal(version.description, "1.2.3-beta.1")
  }

  $0.it("is equal to version with the same major, minor, patch and pre-release") {
    try equal(version, Version(major: 1, minor: 2, patch: 3, prerelease: "beta.1"))
  }

  $0.it("is not equal to version with a different major, minor, patch or pre-release") {
    try notEqual(version, Version(major: 0, minor: 2, patch: 3, prerelease: "beta.1"))
    try notEqual(version, Version(major: 1, minor: 0, patch: 3, prerelease: "beta.1"))
    try notEqual(version, Version(major: 1, minor: 2, patch: 0, prerelease: "beta.1"))
    try notEqual(version, Version(major: 1, minor: 2, patch: 3, prerelease: "beta.2"))
  }

  $0.describe("when parsing a string") {
    $0.it("parses the major, minor and patch version") {
      let version = try Version("1.2.3")

      try equal(version.major, 1)
      try equal(version.minor, 2)
      try equal(version.patch, 3)
      try `nil`(version.prerelease)
    }

    $0.it("parses the major, minor, patch with a pre-release component") {
      let version = try Version("1.2.3-beta.1")

      try equal(version.major, 1)
      try equal(version.minor, 2)
      try equal(version.patch, 3)
      try equal(version.prerelease, "beta.1")
    }
  }
}

