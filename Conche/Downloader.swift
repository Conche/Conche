import PathKit


extension GitSource {
  public func download(destination:Path) throws {
    try invoke("git", ["clone", "-b", tag, "--depth", "1", uri, destination.description])
  }
}

