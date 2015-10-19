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

func buildDependencies(conchePath: Path, specifications:[Specification]) throws {
  print("Building Dependencies")

  for spec in specifications.reverse() {
    print("-> \(spec.name)")
    try spec.build(dependencyPath(conchePath, spec), destination: conchePath)
  }
}

public func build() throws {
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

  if !spec.dependencies.isEmpty {
    try downloadDependencies(conchePath, specifications: specifications)
    try buildDependencies(conchePath, specifications: specifications)
  }

  print("Building \(spec.name)")
  try spec.build(Path.current, destination: conchePath)

  if let cliEntryPoints = spec.entryPoints["cli"] {
    if !cliEntryPoints.isEmpty {
      print("Building Entry Points")

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
  }
}

