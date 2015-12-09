#if os(Linux)
import Glibc
#else
import Darwin.libc
#endif
import PathKit


struct InvocationError : ErrorType {
  init(command:String, arguments:[String], code:Int32) {

  }
}

/// Invoke a subprocess
func invoke(command:String, _ arguments:[String]) throws {
  // TODO - Properly invoke subprocess with exec, arguments are not escaped
  let args = arguments.joinWithSeparator(" ")

  fflush(stdout)
  let code = system("\(command) \(args)")

  if code != 0 {
    throw InvocationError(command: command, arguments: arguments, code: code)
  }
}

public func which(command: String) -> String? {
  let path = String.fromCString(getenv("PATH")) ?? ""
  return path.characters.split { $0 == ":" }
                        .map(String.init)
                        .map { Path($0) + command }
                        .filter { $0.exists }
                        .map { $0.description }.first
}

func swiftc(arguments: [String]) throws {
  let swiftc = String.fromCString(getenv("SWIFTC")) ?? "xcrun -sdk macosx swiftc"
  try invoke(swiftc, arguments)
}
