public struct Version : CustomStringConvertible, Equatable, Comparable {
  public let major: Int
  public let minor: Int
  public let patch: Int

  public init(major: Int, minor: Int, patch: Int) {
    self.major = major
    self.minor = minor
    self.patch = patch
  }

  public init(_ value: String) throws {
    let components = value.characters.split { $0 == "." }.map(String.init)
    if components.count == 3, let major = Int(components[0]), minor = Int(components[1]), patch = Int(components[2]) {
      self.major = major
      self.minor = minor
      self.patch = patch
    } else {
      throw Error("Invalid version \(value), not a valid semantic version.")
    }
  }

  public var description:String {
    return "\(major).\(minor).\(patch)"
  }
}

public func == (lhs:Version, rhs:Version) -> Bool {
  return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
}

public func < (lhs:Version, rhs:Version) -> Bool {
  if lhs.major == rhs.major {
    if lhs.minor == rhs.minor {
      return lhs.patch < rhs.patch
    }

    return lhs.minor < rhs.minor
  }

  return lhs.major < rhs.major
}

