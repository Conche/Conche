import Darwin
import PathKit


public func test() throws {
  let spec = try findPodspec()
  if let testSpecification = spec.testSpecification {
    let spectreDependencies = testSpecification.dependencies.filter { $0.name == "Spectre" }
    if spectreDependencies.isEmpty {
      throw Error("Spectre (https://github.com/kylef/Spectre) is the only supported testing framework at the moment.")
    }

    let conchePath = Path(".conche")
    if !conchePath.exists {
      try conchePath.mkdir()
    }

    let cpSource = GitFilesystemSource(name: "CocoaPods", uri: "https://github.com/CocoaPods/Specs")
    let localSource = LocalFilesystemSource(path:Path.current)
    let sources:[SourceType] = [localSource, cpSource]
    let dependency = try Dependency(name:spec.name, requirements:[Requirement(spec.version.description)])
    var normalSpecifications:[Specification]
    do {
      normalSpecifications = try resolve(dependency, sources: sources)
    } catch {
      try cpSource.update()
      normalSpecifications = try resolve(dependency, sources: sources)
    }
    normalSpecifications.removeFirst()
    let testSpecifications = try resolveTestDependencies(spec.testSpecification, sources: sources)
    let specifications = normalSpecifications + testSpecifications

    try downloadDependencies(conchePath, specifications: specifications)
    try buildDependencies(conchePath, specifications: specifications)

    print("Building \(spec.name)")
    try spec.build(Path.current, destination: conchePath)

    // Spectre tests
    let testFiles = testSpecification.sourceFiles.reduce([Path]()) { (accumulator, file) in
      let files = Path.current.glob(file)
      return accumulator + files
    }

    // Build it all into one file
    // TODO, this is the worst, improve significantly
    let specNames = specifications.map { $0.name } + [spec.name]
    let flags = specNames.map { "-l\($0)" }.joinWithSeparator(" ")

    print("Building test")
    let swiftFlags = "-I .conche/modules -L .conche/lib \(flags)"
    let test = Path(".conche/test.swift")
    var output = ""
    for file in testFiles {
      output += try file.read()
    }
    try test.write(output)
    try swiftc([swiftFlags, "-o", ".conche/test", test.description])

    print("Running Tests")
    try invoke("./.conche/test", [])
  } else {
    throw Error("No test specification found in \(spec.name).")
  }
}
