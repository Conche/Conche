import Darwin
import Commander
import PathKit
import Conche


Group {
  $0.command("build") {
    do {
      let spec = try findPodspec()

      let source = FilesystemSource(path: Path("~/.cocoapods/repos/master").normalize())
      let resolver = DependencyResolver(specification: spec, sources: [source])
      let specifications = try resolver.resolve()

      // Download Specifications

      print("Building Dependencies")

      for spec in specifications {
        print("-> \(spec.name)")
        let source = Path(".conche") + "packages" + spec.name
        if !source.exists {
          print("Source not found.")
          exit(1)
        }

        try spec.build(source, destination: Path(".conche"))
      }

      print("Building \(spec.name)")
      try spec.build(Path.current, destination: Path(".conche"))

      if !spec.entryPoints.isEmpty {
        print("Building Entry Points")

        let bindir = Path(".conche/bin")
        if !bindir.exists {
          try bindir.mkdir()
        }

        let libraries = (specifications + [spec]).map { "-l\($0.name)" }.joinWithSeparator(" ")

        for (name, source) in spec.entryPoints {
          print("-> \(name) -> .conche/bin/\(name)")
          system("swiftc -I .conche/modules -L .conche/lib \(libraries) -o .conche/bin/\(name) \(source)")
        }
      }

    } catch {
      print(error)
      exit(1)
    }
  }
}.run()

