
import XCTest

@MainActor
final class FromQueryUITests: XCTestCase {
  let navBarName = "FromQuery"
  var app: XCUIApplication!
  var collectionViewsQuery: XCUIElementQuery { app.collectionViews }

  override func setUp() async throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["UITEST"]
    app.launch()
    app.buttons[navBarName].tap()
    XCTAssertTrue(app.navigationBars[navBarName].waitForExistence(timeout: 1.0))
  }

  func testActorNameOrdering() throws {
    let add = app.navigationBars[navBarName].buttons["add"]
    add.tap()

    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 6)
    print(collectionViewsQuery.staticTexts.debugDescription)

    let firstMovie = collectionViewsQuery.staticTexts.element(boundBy: 0)
    let firstMovieTitle = "The Island of Dr. Moreau"
    XCTAssertEqual(firstMovie.label, firstMovieTitle)
    firstMovie.tap()

    let navBar = app.navigationBars[firstMovieTitle]
    let backButton = navBar.buttons[navBarName]
    XCTAssertTrue(backButton.waitForExistence(timeout: 1.0))
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 10)

    let titleSortMenu = navBar
      .children(matching: .other).element(boundBy: 0)
      .children(matching: .other).element
      .children(matching: .button).element
    titleSortMenu.tap()
    collectionViewsQuery.buttons["arrow.down"].tap()

    XCTAssertEqual(collectionViewsQuery.staticTexts.element(boundBy: 0).label, "Val Kilmer")
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 10)

    titleSortMenu.tap()
    collectionViewsQuery.buttons["arrow.up"].tap()
    XCTAssertEqual(collectionViewsQuery.staticTexts.element(boundBy: 0).label, "Daniel Rigney")
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 10)

    titleSortMenu.tap()
    collectionViewsQuery.buttons["alternatingcurrent"].tap()
    // Cannot test specific entities due to randomly ordered contents
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 10)

    navBar.buttons["favorite movie"].tap()
    backButton.tap()
    XCTAssertTrue(app.navigationBars[navBarName].waitForExistence(timeout: 1.0))
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 6)
    XCTAssertEqual(firstMovie.label, "Favorited " + firstMovieTitle)
  }

  func testMovieNameOrdering() throws {
    let navBar = app.navigationBars[navBarName]
    let add = navBar.buttons["add"]
    add.tap()

    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 6) // 3 movies, each with title and actor labels

    let firstMovie = collectionViewsQuery.staticTexts.element(boundBy: 0)
    let lastMovie = collectionViewsQuery.staticTexts.element(boundBy: 4)
    let firstMovieTitle = "The Island of Dr. Moreau"
    let lastMovieTitle = "Superman"
    XCTAssertEqual(firstMovie.label, firstMovieTitle)
    XCTAssertEqual(lastMovie.label, lastMovieTitle)

    let titleSortMenu = navBar
      .children(matching: .other).element(boundBy: 0)
      .children(matching: .other).element
      .children(matching: .button).element
    titleSortMenu.tap()
    collectionViewsQuery.buttons["arrow.down"].tap()

    XCTAssertEqual(firstMovie.label, lastMovieTitle)
    XCTAssertEqual(lastMovie.label, firstMovieTitle)
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 6)

    titleSortMenu.tap()
    collectionViewsQuery.buttons["arrow.up"].tap()
    XCTAssertEqual(firstMovie.label, firstMovieTitle)
    XCTAssertEqual(lastMovie.label, lastMovieTitle)
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 6)

    titleSortMenu.tap()
    collectionViewsQuery.buttons["alternatingcurrent"].tap()
    // Cannot test specific entities due to randomly ordered contents
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 6)
  }

  func testFavoriteSwiping() throws {
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 4) // 2 movies, each with title and actor labels

    let firstMovie = collectionViewsQuery.staticTexts.element(boundBy: 0)
    let firstMovieTitle = "Favorited The Score"
    XCTAssertEqual(firstMovie.label, firstMovieTitle)

    firstMovie.gentleSwipeLeft()
    var button = collectionViewsQuery.buttons["unfavorite movie"]
    button.tap()
    XCTAssertEqual(firstMovie.label, "The Score")

    let secondMovie = collectionViewsQuery.staticTexts.element(boundBy: 2)
    let secondMovieTitle = "Superman"
    XCTAssertEqual(secondMovie.label, secondMovieTitle)

    secondMovie.gentleSwipeLeft()
    button = collectionViewsQuery.buttons["favorite movie"]
    button.tap()
    XCTAssertEqual(secondMovie.label, "Favorited Superman")

    // print(collectionViewsQuery.descendants(matching: .button).debugDescription)
  }

  func testDeleteSwiping() throws {
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 4) // 2 movies, each with title and actor labels

    let firstMovie = collectionViewsQuery.staticTexts.element(boundBy: 0)
    let firstMovieTitle = "Favorited The Score"
    XCTAssertEqual(firstMovie.label, firstMovieTitle)

    firstMovie.gentleSwipeLeft()
    let button = collectionViewsQuery.buttons["Delete"]
    button.tap()
    XCTAssertEqual(firstMovie.label, "Superman")
  }

  func testFastSwipingDoesNothingSpecial() throws {
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 4) // 2 movies, each with title and actor labels

    let firstMovie = collectionViewsQuery.staticTexts.element(boundBy: 0)
    let firstMovieTitle = "Favorited The Score"
    XCTAssertEqual(firstMovie.label, firstMovieTitle)

    firstMovie.swipeLeft(velocity: .fast)
    XCTAssertTrue(collectionViewsQuery.buttons["Delete"].exists)
  }
}
