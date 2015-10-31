import Darwin
import PathKit
import Commander
import Conche


Group {
  $0.command("build") {
    try build()
  }

  $0.command("test", VaradicArgument<String>("files")) { files in
    try test(files)
  }

  $0.command("exec") { (command:String, parser:ArgumentParser) in
    let exec = "\(command) \(parser)"
    let conchePath = Path(".conche").absolute() + "bin"
    exit(system("PATH=\(conchePath) \(exec)"))
  }

  $0.command("clean",
             Flag("full", description: "Completely removes source files for all dependencies"),
             description: "Removes build artifacts")
  { (full:Bool) in
    var paths = [Path]()
    let conchePath = Path(".conche")

    if full {
      paths.append(conchePath)
    } else {
      paths.append(conchePath + "bin")
      paths.append(conchePath + "lib")
      paths.append(conchePath + "modules")
    }

    try paths.filter { $0.exists }.forEach { try $0.delete() }
    print("Cleaned")
  }

  $0.command("install", Option("prefix", "/usr/local")) { `prefix` in
    try install(`prefix`)
  }

  $0.command("init",
             Flag("with-tests", `default`: false),
             Flag("with-cli", `default`: false),
             Argument<String>("name"),
             description: "Crete a new Conche project"
  ) { withTests, withCLI, name in
    try initCommand(name, withCLI: withCLI, withTests: withTests)
  }

  $0.unknownCommand = { name, parser in
    let executable = "conche-\(name)"

    if let path = which(executable) {
      exit(system("\(path) \(parser)"))
    }

    throw GroupError.UnknownCommand(name)
  }
}.run("0.5.0")
