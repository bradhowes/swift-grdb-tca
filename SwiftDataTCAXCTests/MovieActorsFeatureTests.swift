import ComposableArchitecture
import Dependencies
import Foundation
import SnapshotTesting
import SwiftData
import XCTest

@testable import SwiftDataTCA


final class MovieActorsFeatureTests: XCTestCase {

  var store: TestStore<MovieActorsFeature.State, MovieActorsFeature.Action>!
  var context: ModelContext { store.dependencies.modelContextProvider }

  override func setUpWithError() throws {
    // isRecording = true
    store = try withDependencies {
      $0.modelContextProvider = try makeTestContext(mockCount: 3)
      $0.continuousClock = ImmediateClock()
    } operation: {
      @Dependency(\.modelContextProvider) var context
      let movies = try context.fetch(FetchDescriptor<MovieModel>())
      let store = TestStore(initialState: MovieActorsFeature.State(movie: movies[0].valueType)) {
        MovieActorsFeature()
      }
      return store
    }
  }

  override func tearDownWithError() throws {
    context.container.deleteAllData()
  }

  @MainActor
  func testNameSortChanged() async throws {
    XCTAssertEqual(store.state.movie.name, "The Score")
    XCTAssertEqual(store.state.actors.count, 5)

    await store.send(.nameSortChanged(.reverse)) {
      $0.nameSort = .reverse
      $0.actors = $0.actors.reversed()
    }

    await store.send(.nameSortChanged(.forward)) {
      $0.nameSort = .forward
      $0.actors = $0.actors.reversed()
    }

    store.exhaustivity = .off
    await store.send(.nameSortChanged(.none)) {
      $0.nameSort = nil
    }

    let names = Set(store.state.actors.map { $0.name })
    XCTAssertEqual(names.count, 5)

    XCTAssertTrue(names.contains(store.state.actors[0].name))
    XCTAssertTrue(names.contains(store.state.actors[1].name))
    XCTAssertTrue(names.contains(store.state.actors[2].name))
    XCTAssertTrue(names.contains(store.state.actors[3].name))
    XCTAssertTrue(names.contains(store.state.actors[4].name))
  }

  @MainActor
  func testFavoriteTapped() async throws {
    XCTAssertTrue(store.state.movie.favorite)
    await store.send(.favoriteTapped) {
      $0.movie = $0.movie.toggleFavorite()
    }
    XCTAssertFalse(store.state.movie.favorite)
    await store.send(.favoriteTapped) {
      $0.movie = $0.movie.toggleFavorite()
      $0.animateButton = true
    }
    XCTAssertTrue(store.state.movie.favorite)
  }

  @MainActor
  func __NO__testPreviewRender() throws {
    try withDependencies {
      $0.modelContextProvider = ModelContextKey.previewValue
    } operation: {
      try withSnapshotTesting(record: .failed) {
        let view = MovieActorsView.preview
        try assertSnapshot(matching: view)
      }
    }
  }
}
