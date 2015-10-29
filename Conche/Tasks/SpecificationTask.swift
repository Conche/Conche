import PathKit


extension DependencyGraph {
  func buildTask() throws -> SpecificationBuildTask {
    let conchePath = Path(".conche")
    let source = Path.current
    let task = try SpecificationBuildTask(specification: root, source: source, destination: conchePath)

    var currentTask = task
    var tasks: [String: Task] = [:]

    func appendSubTasks(dependencyGraph: DependencyGraph) throws {
      let specification = dependencyGraph.root
      if let task = tasks[specification.name] {
        currentTask.dependencies.append(task)
      } else {
        let source = dependencyPath(conchePath, specification)
        let task = try SpecificationBuildTask(specification: specification, source: source, destination: conchePath)

        currentTask.dependencies.append(task)

        let previousTask = currentTask
        currentTask = task
        try dependencyGraph.dependencies.forEach(appendSubTasks)
        currentTask = previousTask
        tasks[specification.name] = task
      }
    }

    try dependencies.forEach(appendSubTasks)

    return task
  }
}

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

    dependencies = []

    let downloadTask = SpecificationDownloadTask(specification: specification, destination: source)
    dependencies.append(downloadTask)
  }

  var name: String {
    return "Building \(specification.name)"
  }

  func moduleBuildTask() throws -> ModuleBuildTask {
    let moduleSearchPath = destination + "modules"
    let librarySearchPath = destination + "lib"
    return try specification.moduleBuildTask(source, moduleSearchPath: moduleSearchPath, librarySearchPath: librarySearchPath)
}

  var isRequired: Bool {
    let task = try? moduleBuildTask()
    return task?.isRequired ?? true
  }

  func run() throws {
    let task = try moduleBuildTask()
    try task.run()
  }
}
