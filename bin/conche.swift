import Darwin
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
}.run()

