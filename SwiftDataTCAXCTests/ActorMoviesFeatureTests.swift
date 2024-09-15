import ComposableArchitecture
import Dependencies
import Foundation
import SnapshotTesting
import SwiftData
import SwiftUI
import XCTest

@testable import SwiftDataTCA

final class ActorMoviesFeatureTests: XCTestCase {

  var store: TestStore<ActorMoviesFeature.State, ActorMoviesFeature.Action>!
  var context: ModelContext { store.dependencies.modelContextProvider }

  override func setUpWithError() throws {
    store = try withDependencies {
      $0.modelContextProvider = try makeTestContext(mockCount: 3)
      $0.continuousClock = ImmediateClock()
    } operation: {
      @Dependency(\.modelContextProvider) var context
      let movies = try context.fetch(FetchDescriptor<MovieModel>())
      let actor = movies[0].valueType.actors(ordering: .forward)[2]
      return TestStore(initialState: ActorMoviesFeature.State(actor: actor)) { ActorMoviesFeature() }
    }
  }

  override func tearDownWithError() throws {
    context.container.deleteAllData()
  }

  @MainActor
  func testDetailButtonTapped() async throws {
    await store.send(.detailButtonTapped(store.state.movies[0]))
  }

  @MainActor
  func testFavoriteSwiped() async throws {
    let movieIndex = 2
    XCTAssertEqual(store.state.movies[movieIndex].name, "Superman")

    XCTAssertFalse(store.state.movies[movieIndex].favorite)
    await store.send(.favoriteSwiped(store.state.movies[movieIndex]))
    await store.receive(\.toggleFavoriteState) {
      $0.movies[movieIndex] = $0.movies[movieIndex].toggleFavorite()
    }
    XCTAssertTrue(store.state.movies[movieIndex].favorite)
    await store.send(.favoriteSwiped(store.state.movies[movieIndex]))
    await store.receive(\.toggleFavoriteState) {
      $0.movies[movieIndex] = $0.movies[movieIndex].toggleFavorite()
    }
    XCTAssertFalse(store.state.movies[movieIndex].favorite)
  }

  @MainActor
  func testRefresh() async throws {
    await store.send(.refresh)
  }

  @MainActor
  func testTitleSortChanged() async throws {
    XCTAssertEqual(store.state.actor.name, "Marlon Brando")
    XCTAssertEqual(store.state.movies.count, 3)

    await store.send(.titleSortChanged(.reverse)) {
      $0.titleSort = .reverse
      $0.movies = $0.movies.reversed()
    }

    await store.send(.titleSortChanged(.forward)) {
      $0.titleSort = .forward
      $0.movies = $0.movies.reversed()
    }

    store.exhaustivity = .off
    await store.send(.titleSortChanged(.none)) {
      $0.titleSort = nil
    }

    let titles = Set(store.state.movies.map(\.name))
    XCTAssertEqual(titles.count, 3)
    for movie in store.state.movies {
      XCTAssertTrue(titles.contains(movie.name))
    }
  }

  @MainActor
  func testPreviewRender() throws {
    try withDependencies {
      $0.modelContextProvider = ModelContextKey.previewValue
    } operation: {
      try withSnapshotTesting(record: .missing) {
        let view = ActorMoviesView.preview
        try assertSnapshot(matching: view)
      }
    }
  }
}

private struct TestApp: App {
  var body: some Scene {
    WindowGroup {
    }
  }
}
