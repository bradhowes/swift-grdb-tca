
import XCTest

final class SwiftDataTCAUITests: XCTestCase {

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  override func tearDownWithError() throws {
  }

  @MainActor
  func testExample() throws {
    let app = XCUIApplication()
    app.launchArguments = ["UITEST"]
    app.launch()

    app.navigationBars["FromState"].children(matching: .button).element.tap()

    let collectionViewsQuery = app.collectionViews
    collectionViewsQuery.buttons["The Score, Angela Bassett, Edward Norton, Marlon Brando, Paul Soles, and Robert De Niro"].tap()
    collectionViewsQuery.buttons["Edward Norton, The Score"].tap()
    app.navigationBars["Edward Norton"].buttons["The Score"].tap()

    let theScoreNavigationBar = app.navigationBars["The Score"]

    theScoreNavigationBar.buttons["Favorite"].tap()
    theScoreNavigationBar.buttons["Favorite"].tap()

    theScoreNavigationBar.buttons["FromState"].tap()
  }

  @MainActor
  func testExample2() throws {

  }
//  @MainActor
//  func testLaunchPerformance() throws {
//    if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
//      // This measures how long it takes to launch your application.
//      measure(metrics: [XCTApplicationLaunchMetric()]) {
//        XCUIApplication().launch()
//      }
//    }
//  }
}

