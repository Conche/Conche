import Spectre
import Conche

func truth(@autoclosure closure: () -> Bool) throws {
  if !closure() {
    try fail("is not true")
  }
}

func falsy(@autoclosure closure: () -> Bool) throws {
  if closure() {
    try fail("is not false")
  }
}

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

  $0.it("is hashable") {
    let items = [version: 66]
    try equal(items[version], 66)
  }

  $0.it("can be converted to a string") {
    try equal(version.description, "1.2.3-beta.1")
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

  $0.context("when comparing two versions") {
    func v(major:Int, _ minor:Int? = nil, _ patch:Int? = nil) -> Version {
      return Version(major: major, minor: minor, patch: patch)
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


    $0.context("with the more than operator") {
      $0.it("returns whether a version is more than another version") {
        let requirement = v(3, 1, 2)
        try truth(v(3, 1, 3) > requirement)
        try truth(v(3, 2, 2) > requirement)
        try truth(v(4, 1, 3) > requirement)
        try falsy(v(3, 1, 2) > requirement)
        try falsy(v(2, 1, 2) > requirement)
      }
    }

    $0.context("with the optimistic operator") {
      $0.it("returns whether a version satisfies using a major version") {
        let requirement = v(3)
        try truth(v(3, 3, 0) ~> requirement)
        try truth(v(4, 0, 0) ~> requirement)
      }

      $0.it("returns whether a version satisfies using a minor version") {
        let requirement = v(3, 2)
        try truth(v(3, 2) ~> requirement)
        try truth(v(3, 2, 0) ~> requirement)
        try truth(v(3, 2, 1) ~> requirement)
        try truth(v(3, 3) ~> requirement)
        try truth(v(3, 3, 0) ~> requirement)
        try falsy(v(4, 0, 0) ~> requirement)
      }

      $0.it("returns whether a version satisfies using a patch version") {
        let requirement = v(3, 2, 0)
        try truth(v(3, 2) ~> requirement)
        try truth(v(3, 2, 0) ~> requirement)
        try truth(v(3, 2, 1) ~> requirement)
        try falsy(v(3, 3) ~> requirement)
        try falsy(v(3, 3, 0) ~> requirement)
        try falsy(v(4, 0, 0) ~> requirement)
      }
    }
  }
}
