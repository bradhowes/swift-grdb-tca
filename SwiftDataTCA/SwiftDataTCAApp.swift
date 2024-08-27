import Dependencies
import SwiftData
import SwiftUI

struct SwiftDataTCAApp: App {
  var body: some Scene {
    WindowGroup {
      RootFeatureView()
    }
  }
}

struct TestApp: App {
  var body: some Scene {
    WindowGroup {
      Text("I'm running tests!")
    }
  }
}

@main
enum AppTrampoline {
  static func main() {
    // `isTest` is set in the testplan's shared configuration settings
    let isTest = UserDefaults.standard.bool(forKey: "isTest")
    if isTest || NSClassFromString("XCTestCase") != nil {
      TestApp.main()
    } else {
      SwiftDataTCAApp.main()
    }
  }
}
