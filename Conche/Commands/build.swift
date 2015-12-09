#if os(Linux)
import Glibc
#else
import Darwin
#endif
import PathKit


func dependencyPath(conchePath:Path, _ spec:Specification) -> Path {
  let packagesPath = conchePath + "packages"
  return packagesPath + spec.name
}

func downloadDependencies(conchePath: Path, specifications: [Specification]) throws {
  let downloadSources = specifications.filter { !dependencyPath(conchePath, $0).exists }
  if !downloadSources.isEmpty {
    print("Downloading Dependencies")
    for spec in downloadSources {
      print("-> \(spec.name)")
      if let source = spec.source {
        try source.download(dependencyPath(conchePath, spec))
      } else {
        print("git / tag source not found.")
        exit(1)
      }
    }
  }
}

func resolve(specification: Specification) throws -> DependencyGraph {
  let cpSource = GitFilesystemSource(name: "CocoaPods", uri: "https://github.com/CocoaPods/Specs")
  let localSource = LocalFilesystemSource(path: Path.current)
  let dependency = try Dependency(name: specification.name, requirements: [Requirement(specification.version.description)])
  let dependencyGraph: DependencyGraph
  do {
    dependencyGraph = try resolve(dependency, sources: [localSource, cpSource])
  } catch {
    try cpSource.update()
    dependencyGraph = try resolve(dependency, sources: [localSource, cpSource])
  }
  return dependencyGraph
}

func buildTask() throws -> Task {
  let spec = try findPodspec()
  let conchePath = Path(".conche")
  if !conchePath.exists {
    try conchePath.mkdir()
  }
  let moddir = conchePath + "modules"
  if !moddir.exists { try moddir.mkdir() }
  let libdir = conchePath + "lib"
  if !libdir.exists { try libdir.mkdir() }

  let dependencyGraph = try resolve(spec)
  let task = try dependencyGraph.buildTask()

  if let cliEntryPoints = spec.entryPoints["cli"] {
    if !cliEntryPoints.isEmpty {
      let cliTask = AnonymousTask("Building Entry Points") {
        let bindir = conchePath + "bin"
        if !bindir.exists {
          try bindir.mkdir()
        }

        let libraries = dependencyGraph.flatten().map { $0.name } + [spec.name]
        let flags = libraries.map { "-l\($0)" }.joinWithSeparator(" ")

        for (name, source) in cliEntryPoints {
          let destination = bindir + name
          let libdir = conchePath + "lib"
          let modulesdir = conchePath + "modules"
          print("-> \(name) -> \(destination)")
          try swiftc(["-I", modulesdir.description, "-L", libdir.description, flags, "-o", destination.description, source])
        }
      }

      cliTask.dependencies.append(task)
      return cliTask
    }
  }

  return task
}

public func build() throws {
  try runTask(try buildTask())
}

public func install(destination: String) throws {
  let destinationPath = Path(destination)
  let conchePath = Path(".conche")

  try destinationPath.mkpath()

  let specification = try findPodspec()
  guard let cliEntryPoints = specification.entryPoints["cli"] where !cliEntryPoints.isEmpty else {
    throw Error("\(specification.name) does not have any installable tools.")
  }

  let task = AnonymousTask("Installing \(specification.name)") {
    let destinationBinDir = destinationPath + "bin"
    let destinationLibDir = destinationPath + "lib" + specification.name

    try destinationBinDir.mkpath()
    try destinationLibDir.mkpath()

    // Copy libraries
    let dependencyGraph = try resolve(specification)
    let specifications = dependencyGraph.flatten()
    let libraries = specifications.map { $0.name }

    for library in libraries {
      let source: Path = conchePath + "lib" + "lib\(library).dylib"
      let destination = destinationLibDir + "lib\(library).dylib"
      if destination.exists {
        try destination.delete()
      }
      try source.copy(destination)
    }

    // Update library search paths
    func updateSearchPath(dependency: String, binary: Path) throws {
      try invoke("install_name_tool", [
        "-change",
        ".conche/lib/lib\(dependency).dylib",
        "@executable_path/../lib/\(specification.name)/lib\(dependency).dylib",
        binary.description,
      ])
    }
    func updateLibSearchPath(dependencyGraph: DependencyGraph) throws {
      let library = destinationLibDir + "lib\(dependencyGraph.root.name).dylib"
      for dependency in dependencyGraph.dependencies {
        try updateSearchPath(dependency.root.name, binary: library)
      }

      try dependencyGraph.dependencies.forEach(updateLibSearchPath)
    }
    try updateLibSearchPath(dependencyGraph)

    // Copy binary
    for (entryPoint, _) in cliEntryPoints {
      let source: Path = conchePath + "bin" + entryPoint
      let destination = destinationBinDir + entryPoint
      if destination.exists {
        try destination.delete()
      }
      try source.copy(destination)

      for specification in dependencyGraph.flatten() {
        try updateSearchPath(specification.name, binary: destination)
      }
      try updateSearchPath(specification.name, binary: destination)
    }
  }

  task.dependencies.append(try buildTask())
  try runTask(task)
}
