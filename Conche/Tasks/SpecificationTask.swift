import PathKit

class SpecificationDownloadTask : Task {
  let specification: Specification
  let destination: Path

  init(specification: Specification, destination: Path) {
    self.specification = specification
    self.destination = destination
  }

  var name: String {
    return "Downloading \(specification.name) \(specification.version)"
  }

  var isRequired: Bool {
    return !destination.exists
  }

  func run() throws {
    if let source = specification.source {
      try source.download(destination)
    } else {
      throw Error("git / tag source not found.")
    }
  }
}

class SpecificationBuildTask : Task {
  let specification: Specification
  let source: Path
  let destination: Path

  init(specification: Specification, source: Path, destination: Path) {
    self.specification = specification
    self.source = source
    self.destination = destination
  }

  var name: String {
    return "Building \(specification.name)"
  }

  var isRequired: Bool {
    if !specification.dependencies.isEmpty {
      return true  // We don't correctly track dependencies yet
    }

    let outputFiles = [
      destination + "lib" + "lib\(name).dylib",
      destination + "modules" + "\(name).swiftmodule",
    ]

    if let lastModified = try? specification.computeSourceFiles(source).lastModified,
           outputModified = outputFiles.lastModified {
      let outputExists = outputFiles.map { $0.exists }.filter { $0 == false }.first ?? true
      return lastModified > outputModified && outputExists
    }

    return true
  }

  var dependencies: [Task] {
    return [
      SpecificationDownloadTask(specification: specification, destination: source)
    ]
  }

  func run() throws {
    try specification.build(source, destination: destination)
  }
}
