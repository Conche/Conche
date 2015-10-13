public protocol DependencySpecificationBuilder {
  func dependency(dependency:Dependency)
  func dependency(name:String, _ requirements:[String])
  func dependency(name:String, _ requirement:String)
  func dependency(name:String)
}

public protocol SpecificationBuilder : DependencySpecificationBuilder {
  func testSpecification(closure:TestSpecificationBuilder -> ())
}

public protocol TestSpecificationBuilder : DependencySpecificationBuilder {

}

class BaseSpecificationBuilder : DependencySpecificationBuilder, SpecificationBuilder, TestSpecificationBuilder {
  var dependencies = [Dependency]()
  var testSpecification:TestSpecification? = nil

  func dependency(dependency:Dependency) {
    dependencies.append(dependency)
  }

  func dependency(name:String, _ requirements:[String]) {
    dependency(Dependency(name: name, requirements: requirements))
  }

  func dependency(name:String, _ requirement:String) {
    dependency(name, [requirement])
  }

  func dependency(name:String) {
    dependency(name, [])
  }

  func testSpecification(closure:TestSpecificationBuilder -> ()) {
    let builder = BaseSpecificationBuilder()
    closure(builder)

    testSpecification = TestSpecification(sourceFiles: [], dependencies: builder.dependencies)
  }
}
