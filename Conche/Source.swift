import PathKit


public protocol SourceType {
  func search(dependency:Dependency) -> [Specification]
}


public class FilesystemSource : SourceType {
  let path:Path

  public init(path:Path) {
    self.path = path
  }

  // TODO, silent error handling
  public func search(dependency:Dependency) -> [Specification] {
    let children = try? (path + "Specs" + dependency.name).children()
    let versions = children ?? []
    let files = versions.map { path in
      return path + "\(dependency.name).podspec.json"
    }
    return files.flatMap { path in
      do {
        return try Specification(path: path)
      } catch {
        print("\(path): \(error)")
        return nil
      }
    } ?? []
  }
}

