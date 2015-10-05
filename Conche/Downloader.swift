import Darwin
import PathKit


extension GitSource {
  public func download(destination:Path) {
    // TODO escape
    let command = "git clone -b \(tag) \(uri) \(destination)"
    system(command)
  }
}

