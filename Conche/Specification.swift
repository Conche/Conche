import Foundation
import PathKit

public struct GitSource {
  public let uri:String
  public let tag:String
}


public struct Specification {
  public let name:String
  public let version:String

  // TODO Make source a protocol and support others
  public let source:GitSource?
  public let sourceFiles:[String]
  public let dependencies:[Dependency]
  public let entryPoints:[String:[String:String]]
}


func parseDependencies(dependencies:[String:[String]]) -> [Dependency] {
  return dependencies.map { (name, requirements) in
    Dependency(name: name, requirements: requirements)
  }
}

func parseSource(source:[String:String]?) -> GitSource? {
  if let source = source, git = source["git"], tag = source["tag"] {
    return GitSource(uri: git, tag: tag)
  }

  return nil
}

extension Specification {
  public init(spec:[String:AnyObject]) throws {
    if let sourceFiles = spec["source_files"] as? [String] {
      self.sourceFiles = sourceFiles
    } else if let sourceFiles = spec["source_files"] as? String {
      self.sourceFiles = [sourceFiles]
    } else {
      throw Error("Invalid podspec. Missing source files.")
    }

    if let name = spec["name"] as? String,
           version = spec["version"] as? String {
      self.name = name
      self.version = version
      self.dependencies = parseDependencies(spec["dependencies"] as? [String:[String]] ?? [:])
      self.entryPoints = spec["entry_points"] as? [String:[String:String]] ?? [:]
      self.source = parseSource(spec["source"] as? [String:String])
    } else {
      // TODO fail on subspecs and unsupported vendored_*, resources etc
      throw Error("Invalid podspec")
    }
  }

  public init(path:Path) throws {
    let data = try NSJSONSerialization.JSONObjectWithData(try path.read(), options: NSJSONReadingOptions(rawValue: 0))
    if let data = data as? [String:AnyObject] {
      try self.init(spec: data)
    } else {
      throw Error("Invalid podspec")
    }
  }
}


struct Error : ErrorType {
  let message:String

  init(_ message:String) {
    self.message = message
  }
}


/// Finds a podspec in the current working directory
public func findPodspec() throws -> Specification {
  let paths = try Path.current.children().filter { $0.description.hasSuffix("podspec.json") }
  if paths.count > 1 {
    let podspecs = paths.map { $0.lastComponent }.joinWithSeparator(", ")
    throw Error("Too many podspecs we're found: \(podspecs)")
  } else if let path = paths.first {
    return try Specification(path: path)
  } else {
    throw Error("There are no JSON podspecs in the current working directory.")
  }
}


extension Specification {
  public func build(source:Path, destination:Path) throws {
    var sourceFiles = self.sourceFiles.reduce([Path]()) { (accumulator, file) in
      let files = source.glob(file)
      return accumulator + files
    }

    sourceFiles = sourceFiles.filter { $0.`extension` != "h" }  // Discard headers

    for file in sourceFiles {
      if file.`extension` != "swift" {
        throw Error("Unsupported source file extension \(file.`extension`)")
      }
    }

    let source = sourceFiles.map { $0.description }.joinWithSeparator(" ")
    let libraries = dependencies.map { "-l\($0.name)" }.joinWithSeparator(" ")

    let libdir = destination + "lib"
    if !libdir.exists {
      try libdir.mkdir()
    }
    let library = libdir + "lib\(name).dylib"
    let moduledir = destination + "modules"
    if !moduledir.exists {
      try moduledir.mkdir()
    }
    let module = moduledir + "\(name).swiftmodule"

    // TODO, respect specifications module name
    // TODO, shell-escape
    // TODO support spec's frameworks
    let command = "swiftc -I \(moduledir) -L \(libdir) \(libraries) -module-name \(name) -emit-library -emit-module -emit-module-path \(module) \(source) -o \(library)"
    system(command)
  }
}

