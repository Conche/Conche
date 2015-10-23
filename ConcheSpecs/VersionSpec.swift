import Spectre
import Conche

func truth(@autoclosure closure: () -> Bool) throws {
  if !closure() {
    throw failure("is not true")
  }
}

func falsy(@autoclosure closure: () -> Bool) throws {
  if closure() {
    throw failure("is not false")
  }
}

describe("Version") {
  let version = Version(major: 1, minor: 2, patch: 3, prerelease: "beta.1")

  $0.it("has a major") {
    try expect(version.major) == 1
  }

  $0.it("has a minor") {
    try expect(version.minor) == 2
  }

  $0.it("has a patch") {
    try expect(version.patch) == 3
  }

  $0.it("has a prerelease") {
    try expect(version.prerelease) == "beta.1"
  }

  $0.it("is hashable") {
    let items = [version: 66]
    try expect(items[version]) == 66
  }

  $0.it("can be converted to a string") {
    try expect(version.description) == "1.2.3-beta.1"
  }

  $0.describe("when parsing a string") {
    $0.it("parses the major, minor and patch version") {
      let version = try Version("1.2.3")

      try expect(version.major) == 1
      try expect(version.minor) == 2
      try expect(version.patch) == 3
      try expect(version.prerelease).to.beNil()
    }

    $0.it("parses the major, minor, patch with a pre-release component") {
      let version = try Version("1.2.3-beta.1")

      try expect(version.major) == 1
      try expect(version.minor) == 2
      try expect(version.patch) == 3
      try expect(version.prerelease) == "beta.1"
    }
  }

  $0.context("when comparing two versions") {
    func v(major:Int, _ minor:Int? = nil, _ patch:Int? = nil) -> Version {
      return Version(major: major, minor: minor, patch: patch)
    }

    $0.it("is equal to version with the same major, minor, patch and pre-release") {
      try expect(version) == Version(major: 1, minor: 2, patch: 3, prerelease: "beta.1")
    }

    $0.it("is not equal to version with a different major, minor, patch or pre-release") {
      try expect(version) != Version(major: 0, minor: 2, patch: 3, prerelease: "beta.1")
      try expect(version) != Version(major: 1, minor: 0, patch: 3, prerelease: "beta.1")
      try expect(version) != Version(major: 1, minor: 2, patch: 0, prerelease: "beta.1")
      try expect(version) != Version(major: 1, minor: 2, patch: 3, prerelease: "beta.2")
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
