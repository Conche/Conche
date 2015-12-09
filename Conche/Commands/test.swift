import PathKit

/*
/// A task for building Spectre specs
class SpectreSpecsBuildTask : Task {
  init(sourceFiles: [Path], libraries: [String]) {

  }

  func run() throws {

  }

  internal func x() {

  }
}
*/


public func test(files: [String]) throws {
  let spec = try findPodspec()

  if let testSpecification = spec.testSpecification {
    let spectreDependencies = testSpecification.dependencies.filter { $0.name == "Spectre" }
    if spectreDependencies.isEmpty {
      throw Error("Spectre (https://github.com/kylef/Spectre) is the only supported testing framework at the moment.")
    }

    var tasks: [Task] = [try buildTask()]

    let buildTestTask = AnonymousTask("Building Specs") {
      let testFiles: [Path]

      if files.isEmpty {
        testFiles = testSpecification.sourceFiles.reduce([Path]()) { (accumulator, file) in
          let specificationFiles = Path.current.glob(file)
          return accumulator + specificationFiles
        }
      } else {
        testFiles = files.map { Path($0) }
      }

      let specNames = spec.dependencies.map { $0.name } + testSpecification.dependencies.map { $0.name } + [spec.name]
      let flags = specNames.map { "-l\($0)" }.joinWithSeparator(" ")
      let swiftFlags = "-I .conche/modules -L .conche/lib \(flags)"
      let testFile: Path

      if files.count == 1 {
        testFile = testFiles[0]
      } else {
        // Build it all into one file TODO, this is the worst, improve significantly
        testFile = Path(".conche/test.swift")
        var output = ""
        for file in testFiles {
          output += try file.read()
        }
        try testFile.write(output)
      }

      try swiftc([swiftFlags, "-o", ".conche/test", testFile.description])
    }

    let runTestTask = AnonymousTask("Running Specs") {
      try invoke("./.conche/test", [])
    }

    tasks.append(buildTestTask)
    tasks.append(runTestTask)

    try tasks.forEach(runTask)
  } else {
    throw Error("No test specification found in \(spec.name).")
  }
}
