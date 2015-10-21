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

func buildSpecificationTask(conchePath: Path)(_ spec: Specification) -> Task {
  let source = dependencyPath(conchePath, spec)
  return SpecificationBuildTask(specification: spec, source: source, destination: conchePath)
}

func buildTasks() throws -> [Task] {
  let spec = try findPodspec()
  let conchePath = Path(".conche")
  if !conchePath.exists {
    try conchePath.mkdir()
  }

  let cpSource = GitFilesystemSource(name: "CocoaPods", uri: "https://github.com/CocoaPods/Specs")
  let localSource = LocalFilesystemSource(path:Path.current)
  let dependency = try Dependency(name:spec.name, requirements:[Requirement(spec.version.description)])
  var specifications:[Specification]
  do {
    specifications = try resolve(dependency, sources: [localSource, cpSource])
  } catch {
    try cpSource.update()
    specifications = try resolve(dependency, sources: [localSource, cpSource])
  }

  specifications.removeFirst()

  var tasks = specifications.reverse().map(buildSpecificationTask(conchePath))
  let task = AnonymousTask("Building \(spec.name)") {
    try spec.build(Path.current, destination: conchePath)
  }
  tasks.append(task)

  if let cliEntryPoints = spec.entryPoints["cli"] {
    if !cliEntryPoints.isEmpty {
      let task = AnonymousTask("Building Entry Points") {
        let bindir = conchePath + "bin"
        if !bindir.exists {
          try bindir.mkdir()
        }

        let libraries = (specifications + [spec]).map { "-l\($0.name)" }.joinWithSeparator(" ")

        for (name, source) in cliEntryPoints {
          let destination = bindir + name
          let libdir = conchePath + "lib"
          let modulesdir = conchePath + "modules"
          print("-> \(name) -> \(destination)")
          try swiftc(["-I", modulesdir.description, "-L", libdir.description, libraries, "-o", destination.description, source])
        }
      }

      tasks.append(task)
    }
  }

  return tasks
}

public func build() throws {
  let tasks = try buildTasks()
  try tasks.forEach(runTask)
}
