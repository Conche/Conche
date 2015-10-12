import Darwin


struct InvocationError : ErrorType {
  init(command:String, arguments:[String], code:Int32) {

  }
}

/// Invoke a subprocess
func invoke(command:String, _ arguments:[String]) throws {
  // TODO - Properly invoke subprocess with exec, arguments are not escaped
  let args = arguments.joinWithSeparator(" ")

  let code = system("\(command) \(args)")

  if code != 0 {
    throw InvocationError(command: command, arguments: arguments, code: code)
  }
}

func swiftc(arguments: [String]) throws {
  let swiftc = String.fromCString(getenv("SWIFTC")) ?? "swiftc"
  try invoke(swiftc, arguments)
}
