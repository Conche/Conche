import Darwin
import PathKit


public protocol SourceType {
  func search(dependency:Dependency) -> [Specification]
  func update() throws
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

  var path:Path {
    return Path("~/.conche/sources/\(name)").normalize()
  }

  public func update() throws {
    let destination = path
    if destination.exists {
      path.chdir {
        system("git pull \(uri) master")
      }
    } else {
      system("git clone --depth 1 \(uri) \(path)")
    }
  }
}

