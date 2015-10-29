import Darwin
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

  let cpSource = GitFilesystemSource(name: "CocoaPods", uri: "https://github.com/CocoaPods/Specs")
  let localSource = LocalFilesystemSource(path: Path.current)
  let dependency = try Dependency(name: spec.name, requirements: [Requirement(spec.version.description)])
  let dependencyGraph: DependencyGraph
  do {
    dependencyGraph = try resolve(dependency, sources: [localSource, cpSource])
  } catch {
    try cpSource.update()
    dependencyGraph = try resolve(dependency, sources: [localSource, cpSource])
  }

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
