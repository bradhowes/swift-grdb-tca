import ComposableArchitecture
import Dependencies
import GRDB
import Models
import SwiftUI

struct SwiftDataTCAApp: App {

#if os(iOS)
  init() {
    UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
      .lineBreakMode = .byTruncatingMiddle
  }
#endif

  var body: some Scene {
    let _ = prepareDependencies { // swiftlint:disable:this redundant_discardable_let
      $0.defaultDatabase = try! DatabaseQueue.appDatabase() // swiftlint:disable:this force_try
      // $0.viewLinkType = .button // ProcessInfo.processInfo.arguments.contains("NAVLINKS") ? .navLink : .button
    }
    WindowGroup {
      FromStateView(store: Store(initialState: .init()) { FromStateFeature() })
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
