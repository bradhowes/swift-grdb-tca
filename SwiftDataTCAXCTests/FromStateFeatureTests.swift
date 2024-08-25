import ComposableArchitecture
import Dependencies
import Foundation
import SnapshotTesting
import SwiftData
import XCTest

@testable import SwiftDataTCA

final class FromStateFeatureTests: XCTestCase {

  var store: TestStore<FromQueryFeature.State, FromQueryFeature.Action>!
  var context: ModelContext { store.dependencies.modelContextProvider }

  override func setUpWithError() throws {
    // isRecording = true
    store = try withDependencies {
      $0.modelContextProvider = try makeTestContext()
      $0.continuousClock = ImmediateClock()
    } operation: {
      TestStore(initialState: FromQueryFeature.State()) {
        FromQueryFeature()
      }
    }
  }

  override func tearDownWithError() throws {
    store.dependencies.modelContextProvider.container.deleteAllData()
  }

  @MainActor
  func testAddButtonTapped() async throws {
    store.exhaustivity = .off
    await store.send(.addButtonTapped)

    let movies = try! context.fetch(ActiveSchema.movieFetchDescriptor())

    XCTAssertEqual(1, movies.count)
    XCTAssertEqual("The Score", movies[0].title)
  }

  @MainActor
  func testDeleteSwiped() async throws {
    var movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, searchString: ""))
    XCTAssertTrue(movies.isEmpty)

    await store.send(.addButtonTapped)

    movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, searchString: ""))
    XCTAssertFalse(movies.isEmpty)
    let movie = movies[0].valueType
    await store.send(.deleteSwiped(movie))

    movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, searchString: ""))
    XCTAssertTrue(movies.isEmpty)
  }

  @MainActor
  func testFavoriteSwiped() async throws {
    var movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, searchString: ""))
    XCTAssertTrue(movies.isEmpty)

    await store.send(.addButtonTapped)

    movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, searchString: ""))
    XCTAssertFalse(movies[0].favorite)
    let movie = movies[0].valueType
    await store.send(.favoriteSwiped(movie))
    await store.receive(\.toggleFavoriteState)
    XCTAssertTrue(movies[0].favorite)
  }

  @MainActor
  func testPreviewRender() throws {
    try withDependencies {
      $0.modelContextProvider = ModelContextKey.previewValue
    } operation: {
      try withSnapshotTesting(record: .missing) {
        let view = FromStateView.preview
        try assertSnapshot(matching: view)
      }
    }
  }

  @MainActor
  func testRootContentViewRender() throws {
    try withDependencies {
      $0.modelContextProvider = ModelContextKey.previewValue
    } operation: {
      try withSnapshotTesting(record: .missing) {
        let view = RootContentView.preview
        try assertSnapshot(matching: view)
      }
    }
  }
}
