import Darwin
import PathKit


public func initCommand(name: String, withCLI: Bool, withTests: Bool) throws {
  let destination = Path.current + name
  if destination.exists {
    print("\(name) already exists.")
    exit(1)
  }

  try destination.mkpath()
  let sourceDirectory = destination + name
  try sourceDirectory.mkpath()

  let example = sourceDirectory + "\(name).swift"
  try example.write("// \(name)\n")

  var testSpecification = ""

  if withTests {
    let specsDirectory = destination + "\(name)Specs"
    try specsDirectory.mkpath()

    let exampleSpec = specsDirectory + "\(name)Spec.swift"
    try exampleSpec.write("import Spectre\n\ndescribe(\"\(name)\") {\n  $0.it(\"should be implemented\") {\n    throw failure(\"Not Implemented\")\n  }\n}\n")

    testSpecification = ",\n  \"test_specification\": {\n    \"source_files\": \"\(name)Specs/*.swift\",\n    \"dependencies\": {\n      \"Spectre\": [\"~> 0.5.0\"]\n    }\n  }"
  }

  var entryPoints = ""

  if withCLI {
    let binDirectory = destination + "bin"
    try binDirectory.mkpath()
    let binName = name.lowercaseString
    let cliEntryPoint = binDirectory + "\(binName).swift"
    try cliEntryPoint.write("print(\"Hello \(name)\")\n")
    entryPoints = ",\n  \"entry_points\": {\n    \"cli\": {\n      \"\(binName)\": \"bin/\(binName).swift\"\n    }\n  }"
  }

  let specificationPath = destination + "\(name).podspec.json"
  try specificationPath.write("{\n  \"name\": \"\(name)\",\n  \"version\": \"1.0.0\",\n  \"source_files\": \"\(name)/*.swift\"\(entryPoints)\(testSpecification)\n}\n")

  print("Initialised \(name).")
}
