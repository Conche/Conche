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
    system("PATH=\(conchePath) \(exec)")
  }

  $0.command("clean", Flag("full")) { (full:Bool) in
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
}.run("0.3.0")
