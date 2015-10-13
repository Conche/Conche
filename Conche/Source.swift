import Darwin
import PathKit


public protocol SourceType {
  func search(dependency:Dependency) -> [Specification]
  func update() throws
}

public class LocalFilesystemSource : SourceType {
  let path:Path

  public init(path:String) {
    self.path = Path(path)
  }

  public func search(dependency:Dependency) -> [Specification] {
    let filename = "\(dependency.name).podspec.json"
    let paths = try? path.children().filter { $0.description.hasSuffix(filename) } ?? []
    let specs = paths!.flatMap { (file:Path) in try? Specification(path:file) }
    return specs.filter { dependency.satisfies($0.version) }
  }

  public func update() throws {}
}

public class GitFilesystemSource : SourceType {
  let name:String
  let uri:String

  public init(name:String, uri:String) {
    self.name = name
    self.uri = uri
  }

  // TODO, silent error handling
  public func search(dependency:Dependency) -> [Specification] {
    let children = try? (path + "Specs" + dependency.name).children()
    let podspecs = (children ?? []).map { path in
      return path + "\(dependency.name).podspec.json"
    }

    return podspecs.flatMap(loadFile)
  }


  func loadFile(path:Path) -> Specification? {
    do {
      return try Specification(path: path)
    } catch {
      print("\(path): \(error)")
      return nil
    }
  }

  var path:Path {
    return Path("~/.conche/sources/\(name)").normalize()
  }

  public func update() throws {
    let destination = path
    if destination.exists {
      try path.chdir {
        try invoke("git", ["pull", uri, "master"])
      }
    } else {
      try invoke("git", ["clone", "--depth", "1", uri, path.description])
    }
  }
}

