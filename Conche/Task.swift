protocol Task {
  var name: String { get }
  var dependencies: [Task] { get }
  var isRequired: Bool { get }
  func run() throws
}

extension Task {
  var dependencies: [Task] {
    return []
  }

  var isRequired: Bool {
    return true
  }
}

func runTask(task: Task) throws {
  func innerRunTask(task: Task) throws -> Bool {
    let results = try task.dependencies.map { try innerRunTask($0) }
    let didRun = results.filter { $0 }.first ?? false

    if didRun || task.isRequired {
      print("-> \(task.name)")
      try task.run()
      return true
    }

    return false
  }

  try innerRunTask(task)
}

class AnonymousTask : Task {
  let name: String
  let closure: () throws -> ()
  var dependencies: [Task]

  init(_ name: String, dependencies: [Task]? = nil, closure: () throws -> ()) {
    self.name = name
    self.dependencies = dependencies ?? []
    self.closure = closure
  }

  func run() throws {
    try closure()
  }
}
