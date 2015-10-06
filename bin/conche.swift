import Darwin
import PathKit
import Commander
import Conche


Group {
  $0.command("build") {
    do {
      try build()
    } catch {
      print(error)
      exit(1)
    }
  }

  $0.command("exec") { (command:String, parser:ArgumentParser) in
    let exec = "\(command) \(parser)"
    let conchePath = Path(".conche").absolute() + "bin"
    system("PATH=\(conchePath) \(exec)")
  }
}.run()

