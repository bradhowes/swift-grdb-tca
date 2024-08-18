import ComposableArchitecture
import Dependencies
import Foundation
import SnapshotTesting
import SwiftData
import XCTest

@testable import SwiftDataTCA

final class FromStateFeatureTests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
    @Dependency(\.modelContextProvider.container) var container
    container.deleteAllData()
  }

  @MainActor
  func testFromStateAddButtonTapped() async throws {
    let store = TestStore(initialState: FromStateFeature.State()) {
      FromStateFeature()
    }

    XCTAssertTrue(store.state.movies.isEmpty)

    store.exhaustivity = .off
    await store.send(.addButtonTapped)
    await store.receive(\._fetchMovies)

    XCTAssertEqual(1, store.state.movies.count)
    XCTAssertEqual("The Score", store.state.movies[0].name)
  }

  @MainActor
  func testFromStateDeleteSwiped() async throws {
    let store = TestStore(initialState: FromStateFeature.State()) {
      FromStateFeature()
    }

    XCTAssertTrue(store.state.movies.isEmpty)

    store.exhaustivity = .off
    await store.send(.addButtonTapped)
    await store.receive(\._fetchMovies)

    XCTAssertEqual(1, store.state.movies.count)
    XCTAssertEqual("The Score", store.state.movies[0].name)

    await store.send(.deleteSwiped(store.state.movies[0]))
    await store.receive(\._fetchMovies)

    XCTAssertEqual(0, store.state.movies.count)
  }

  @MainActor
  func testFromStateFavoriteSwiped() async throws {
    let store = TestStore(initialState: FromStateFeature.State()) {
      FromStateFeature()
    }

    XCTAssertTrue(store.state.movies.isEmpty)

    store.exhaustivity = .off
    await store.send(.addButtonTapped)
    await store.receive(\._fetchMovies)

    XCTAssertEqual(1, store.state.movies.count)
    XCTAssertEqual("The Score", store.state.movies[0].name)
    XCTAssertFalse(store.state.movies[0].favorite)

    store.exhaustivity = .on
    await store.send(.favoriteSwiped(store.state.movies[0])) {
      $0.movies[0].favorite = true
    }

    // XCTAssertTrue(store.state.movies[0].favorite)
  }

  @MainActor
  func testPreviewRender() throws {
    let view = FromStateView.preview
    try assertSnapshot(matching: view)
  }

  @MainActor
  func testNextMockMovieEntry() async {
  }
}

#if hasFeature(RetroactiveAttribute)
extension FromStateFeature.State: @retroactive Equatable {
  public static func == (lhs: FromStateFeature.State, rhs: FromStateFeature.State) -> Bool {
    lhs.movies == rhs.movies &&
    lhs.titleSort == rhs.titleSort &&
    lhs.isSearchFieldPresented == rhs.isSearchFieldPresented &&
    lhs.searchString == rhs.searchString
  }
}
#else
extension FromStateFeature.State: Equatable {
  public static func == (lhs: FromStateFeature.State, rhs: FromStateFeature.State) -> Bool {
    lhs.movies == rhs.movies &&
    lhs.titleSort == rhs.titleSort &&
    lhs.isSearchFieldPresented == rhs.isSearchFieldPresented &&
    lhs.searchString == rhs.searchString
  }
}
#endif
