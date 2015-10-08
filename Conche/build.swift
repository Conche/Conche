import Darwin
import PathKit


public func build() throws {
  let spec = try findPodspec()
  let conchePath = Path(".conche")
  if !conchePath.exists {
    try conchePath.mkdir()
  }

  let source = GitFilesystemSource(name: "CocoaPods", uri: "https://github.com/CocoaPods/Specs")
  try source.update()
  let resolver = DependencyResolver(specification: spec, sources: [source])
  let specifications = try resolver.resolve()

  func dependencyPath(spec:Specification) -> Path {
    let packagesPath = conchePath + "packages"
    return packagesPath + spec.name
  }

  if !spec.dependencies.isEmpty {
    let downloadSources = specifications.filter { !dependencyPath($0).exists }
    if !downloadSources.isEmpty {
      print("Downloading Dependencies")
      for spec in downloadSources {
        print("-> \(spec.name)")
        if let source = spec.source {
          source.download(dependencyPath(spec))
        } else {
          print("git / tag source not found.")
          exit(1)
        }
      }
    }

    print("Building Dependencies")

    for spec in specifications {
      print("-> \(spec.name)")
      try spec.build(dependencyPath(spec), destination: conchePath)
    }
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
        system("swiftc -I \(modulesdir) -L \(libdir) \(libraries) -o \(destination) \(source)")
      }
    }
  }
}

