import ComposableArchitecture
import Dependencies
import GRDB
import Models
import SwiftUI

struct SwiftDataTCAApp: App {

  init() {
    prepareDependencies {
      $0.defaultDatabase = try! DatabaseQueue.appDatabase() // swiftlint:disable:this force_try
      // $0.viewLinkType = .button // ProcessInfo.processInfo.arguments.contains("NAVLINKS") ? .navLink : .button
    }
#if os(iOS)
    UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
      .lineBreakMode = .byTruncatingMiddle
#endif
  }

  var body: some Scene {
    WindowGroup {
      RootView(store: Store(initialState: .init()) { RootFeature() })
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
