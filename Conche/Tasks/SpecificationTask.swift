import PathKit

class SpecificationDownloadTask : Task {
  let specification: Specification
  let destination: Path

  init(specification: Specification, destination: Path) {
    self.specification = specification
    self.destination = destination
  }

  var name: String {
    return "Downloading \(specification.name) (\(specification.version))"
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
  var dependencies: [Task]

  init(specification: Specification, source: Path, destination: Path) throws {
    self.specification = specification
    self.source = source
    self.destination = destination

    let moduleSearchPath = destination + "modules"
    let librarySearchPath = destination + "lib"

    dependencies = []

    let downloadTask = SpecificationDownloadTask(specification: specification, destination: source)
    let moduleBuildTask = try specification.moduleBuildTask(source, moduleSearchPath: moduleSearchPath, librarySearchPath: librarySearchPath)
    moduleBuildTask.dependencies.append(downloadTask)
    dependencies.append(moduleBuildTask)
  }

  var name: String {
    return "Building \(specification.name)"
  }

  func run() throws {}
}
