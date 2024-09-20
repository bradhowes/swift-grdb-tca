
import XCTest

final class SwiftDataTCAUITests: XCTestCase {

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  override func tearDownWithError() throws {
  }

  @MainActor
  func testFromState() throws {
    let app = XCUIApplication()
    app.launchArguments = ["UITEST"]
    app.launch()
  }

  @MainActor
  func testNameOrdering() throws {
    let app = XCUIApplication()
    app.launchArguments = ["UITEST"]
    app.launch()

    app.navigationBars["FromState"].children(matching: .button).element.tap()

    let collectionViewsQuery = app.collectionViews
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 6)
    print(collectionViewsQuery.staticTexts.debugDescription)

    collectionViewsQuery.staticTexts["The Island of Dr. Moreau"].tap()

    let navBar = app.navigationBars["The Island of Dr. Moreau"]
    let button = navBar.children(matching: .other).element(boundBy: 0).children(matching: .other).element.children(matching: .button).element
    button.tap()
    collectionViewsQuery.buttons["Down"].tap()
    XCTAssertEqual(collectionViewsQuery.staticTexts.element(boundBy: 0).label, "Val Kilmer")
    button.tap()
    collectionViewsQuery.buttons["Up"].tap()
    XCTAssertEqual(collectionViewsQuery.staticTexts.element(boundBy: 0).label, "Daniel Rigney")
    button.tap()
    collectionViewsQuery.buttons["alternatingcurrent"].tap()

    navBar.buttons["Favorite"].tap()

    navBar.buttons["FromState"].tap()
  }

//  @MainActor
//  func testLaunchPerformance() throws {
//    if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
//      // This measures how long it takes to launch your application.
//      measure(metrics: [XCTApplicationLaunchMetric()]) {
//        XCUIApplication().launch()
//      }
//    }
//  }'


}

extension XCTestCase {

  @MainActor
  func wait(for duration: TimeInterval) {
    let waitExpectation = expectation(description: "Waiting")

    let when = DispatchTime.now() + duration
    DispatchQueue.main.asyncAfter(deadline: when) {
      waitExpectation.fulfill()
    }

    // We use a buffer here to avoid flakiness with Timer on CI
    waitForExpectations(timeout: duration + 0.5)
  }
}
