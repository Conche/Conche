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

      for specification in specifications {
        print("Building '\(specification.name)'")

        let source:Path
        if spec.name == specification.name {
          source = Path.current
        } else {
          source = Path(".conche") + "packages" + specification.name
        }

        if !source.exists {
          print("Source not found.")
          exit(1)
        }

        try specification.build(source, destination: Path(".conche"))
      }
    } catch {
      print(error)
      exit(1)
    }
  }
}.run()

