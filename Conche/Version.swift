extension String {
  func split(element: Character, maxSplit: Int = Int.max) -> [String] {
    return characters.split(maxSplit, isSeparator: { $0 == element }).map(String.init)
  }
}

/// Represents a semantic version
public struct Version : CustomStringConvertible, Equatable, Comparable {
  public let major: Int
  public let minor: Int
  public let patch: Int
  public let prerelease: String?

  public init(major: Int, minor: Int, patch: Int, prerelease: String? = nil) {
    self.major = major
    self.minor = minor
    self.patch = patch
    self.prerelease = prerelease
  }

  public init(_ value: String) throws {
    let prereleaseComponents = value.split("-", maxSplit: 2)
    if prereleaseComponents.count == 2 {
      prerelease = prereleaseComponents.last
    } else {
      prerelease = nil
    }

    let components = prereleaseComponents[0].split(".")
    if components.count == 3, let major = Int(components[0]), minor = Int(components[1]), patch = Int(components[2]) {
      self.major = major
      self.minor = minor
      self.patch = patch
    } else {
      throw Error("Invalid version \(value), not a valid semantic version.")
    }
  }

  public var description:String {
    if let prerelease = prerelease {
      return "\(major).\(minor).\(patch)-\(prerelease)"
    }

    return "\(major).\(minor).\(patch)"
  }
}

public func == (lhs:Version, rhs:Version) -> Bool {
  return lhs.major == rhs.major &&
    lhs.minor == rhs.minor &&
    lhs.patch == rhs.patch &&
    lhs.prerelease == rhs.prerelease
}

public func < (lhs:Version, rhs:Version) -> Bool {
  // TODO prerelease
  if lhs.major == rhs.major {
    if lhs.minor == rhs.minor {
      return lhs.patch < rhs.patch
    }

    return lhs.minor < rhs.minor
  }

  return lhs.major < rhs.major
}

