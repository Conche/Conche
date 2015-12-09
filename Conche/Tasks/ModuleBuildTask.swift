import PathKit


/// A task to build a Swift module
class ModuleBuildTask : Task {
  /// The modules name
  let moduleName: String

  /// The modules source files
  let sources: [Path]

  /// The module search path to look for other dependencies
  /// This is also the destination directory for the build module
  let moduleSearchPath: Path

  /// The library search path to look for other dependencies
  /// This is also the destination directory for the build library
  let librarySearchPath: Path

  /// Libraries to link the module against
  let libraries: [String]

  init(name: String, sources: [Path], moduleSearchPath: Path, librarySearchPath: Path, libraries: [String]? = nil) {
    self.moduleName = name
    self.sources = sources
    self.moduleSearchPath = moduleSearchPath
    self.librarySearchPath = librarySearchPath
    self.libraries = libraries ?? []
  }

  var name: String {
    return "Building \(moduleName) Module"
  }

  var isRequired: Bool {
#if !os(Linux)
    let outputFiles = [ libraryDestination, moduleDestination ]

    if let lastModified = sources.lastModified, outputModified = outputFiles.lastModified {
      let outputExists = outputFiles.map { $0.exists }.filter { $0 == false }.first ?? true
      return !outputExists || lastModified > outputModified
    }
#endif
    return true
  }

  var libraryDestination: Path {
    return librarySearchPath + "lib\(moduleName).dylib"
  }

  var moduleDestination: Path {
    return moduleSearchPath + "\(moduleName).swiftmodule"
  }

  func run() throws {
    try swiftc([
      "-I", moduleSearchPath.description,
      "-L", librarySearchPath.description,
      "-module-name", moduleName,
      "-emit-library",
      "-emit-module",
      "-emit-module-path", moduleDestination.description,
      "-o", libraryDestination.description
    ]
    + libraries.map { "-l\($0)"}
    + sources.map { $0.description })
  }
}


extension Specification {
  /// Creates a module build task to build the specification
  func moduleBuildTask(source: Path, moduleSearchPath: Path, librarySearchPath: Path) throws -> ModuleBuildTask {
    let sources = try computeSourceFiles(source)
    let libraries = self.libraries + dependencies.map { $0.name }
    return ModuleBuildTask(name: name, sources: sources, moduleSearchPath: moduleSearchPath, librarySearchPath: librarySearchPath, libraries: libraries)
  }
}
