import Darwin
import PathKit


public func test() throws {
  let conchePath = Path(".conche")
  let spec = try findPodspec()

  if let testSpecification = spec.testSpecification {
    let spectreDependencies = testSpecification.dependencies.filter { $0.name == "Spectre" }
    if spectreDependencies.isEmpty {
      throw Error("Spectre (https://github.com/kylef/Spectre) is the only supported testing framework at the moment.")
    }

    var tasks = try buildTasks()

    let cpSource = GitFilesystemSource(name: "CocoaPods", uri: "https://github.com/CocoaPods/Specs")
    let testSpecifications = try resolveTestDependencies(spec.testSpecification, sources: [cpSource])
    tasks += testSpecifications.reverse().map(buildSpecificationTask(conchePath))

    let buildTestTask = AnonymousTask("Building Specs") {
      let testFiles = testSpecification.sourceFiles.reduce([Path]()) { (accumulator, file) in
        let files = Path.current.glob(file)
        return accumulator + files
      }

      // Build it all into one file
      // TODO, this is the worst, improve significantly
      let specNames = testSpecifications.map { $0.name } + [spec.name]
      let flags = specNames.map { "-l\($0)" }.joinWithSeparator(" ")

      let swiftFlags = "-I .conche/modules -L .conche/lib \(flags)"
      let test = Path(".conche/test.swift")
      var output = ""
      for file in testFiles {
        output += try file.read()
      }
      try test.write(output)
      try swiftc([swiftFlags, "-o", ".conche/test", test.description])
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
