
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
    XCTAssertTrue(app.navigationBars[navBarName].waitForExistence(timeout: 5.0))
  }

  func testActorNameOrdering() throws {
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 4)

    let firstMovie = collectionViewsQuery.staticTexts.element(boundBy: 0)
    let firstMovieTitle = "The Score"
    XCTAssertEqual(firstMovie.label, "Favorited " + firstMovieTitle)
    firstMovie.tap()

    let navBar = app.navigationBars[firstMovieTitle]
    XCTAssertTrue(navBar.waitForExistence(timeout: 2.0))

    let backButton = navBar.buttons[navBarName]
    XCTAssertTrue(backButton.waitForExistence(timeout: 2.0))
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 10)
    XCTAssertEqual(collectionViewsQuery.staticTexts.element(boundBy: 0).label, "Angela Bassett")

    let titleSortMenu = navBar.buttons["actor ordering, actor ordering, choose actor ordering"]
    app.tapMenuItem(menu: titleSortMenu, button: "arrow.down")

    XCTAssertEqual(collectionViewsQuery.staticTexts.element(boundBy: 0).label, "Robert De Niro")

    app.tapMenuItem(menu: titleSortMenu, button: "alternatingcurrent")
    // Cannot test specific entities due to randomly ordered contents
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 10)

    navBar.buttons["unfavorite movie"].tap()
    backButton.tap()

    XCTAssertTrue(app.navigationBars[navBarName].waitForExistence(timeout: 2.0))
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 4)

    XCTAssertEqual(firstMovie.label, firstMovieTitle)
  }

  func testMovieNameOrdering() throws {
    let navBar = app.navigationBars[navBarName]

    let firstMovie = collectionViewsQuery.staticTexts.element(boundBy: 0)
    let lastMovie = collectionViewsQuery.staticTexts.element(boundBy: 2)
    let firstMovieTitle = "Favorited The Score"
    let lastMovieTitle = "Superman"
    XCTAssertEqual(firstMovie.label, firstMovieTitle)
    XCTAssertEqual(lastMovie.label, lastMovieTitle)

    let titleSortMenu = navBar.buttons["movie ordering, movie ordering, choose movie ordering"]
    app.tapMenuItem(menu: titleSortMenu, button: "arrow.down")

    XCTAssertEqual(firstMovie.label, lastMovieTitle)
    XCTAssertEqual(lastMovie.label, firstMovieTitle)
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 4)

    app.tapMenuItem(menu: titleSortMenu, button: "alternatingcurrent")
    // Cannot test specific entities due to randomly ordered contents
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 4)
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

    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 2) // 2 movies, each with title and actor labels
  }

  func testFastSwipingDoesNothingSpecial() throws {
    XCTAssertEqual(collectionViewsQuery.staticTexts.count, 4) // 2 movies, each with title and actor labels

    let firstMovie = collectionViewsQuery.staticTexts.element(boundBy: 0)
    let firstMovieTitle = "Favorited The Score"
    XCTAssertEqual(firstMovie.label, firstMovieTitle)

    firstMovie.swipeLeft(velocity: .fast)
    XCTAssertTrue(collectionViewsQuery.buttons["Delete"].waitForExistence(timeout: 2.0))
  }
}
