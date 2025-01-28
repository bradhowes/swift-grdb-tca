import ComposableArchitecture
import Dependencies
import Foundation
import IdentifiedCollections
import SnapshotTesting
import SwiftData
import SwiftUI
import XCTest

@testable import SwiftDataTCA

@MainActor
private final class Context {
  let store: TestStoreOf<ActorMoviesFeature>

  init() throws {
    store = try withDependencies {
      $0.modelContextProvider = try makeTestContext(mockCount: 3)
      $0.continuousClock = ImmediateClock()
    } operation: {
      @Dependency(\.modelContextProvider) var context
      let movies = try context.fetch(FetchDescriptor<MovieModel>())
      let actor = movies[0].valueType.actors(ordering: .forward)[2]
      return TestStore(initialState: ActorMoviesFeature.State(actor: actor)) {
        ActorMoviesFeature()
      }
    }
  }
}

final class ActorMoviesFeatureTests: XCTestCase {
  private var ctx: Context!

  override func setUp() async throws {
    await ctx = try Context()
  }

  @MainActor
  func testDetailButtonTapped() async throws {
    await ctx.store.send(.detailButtonTapped(ctx.store.state.movies[0]))
  }

  @MainActor
  func testFavoriteSwiped() async throws {
    let movieIndex = 2
    XCTAssertEqual(ctx.store.state.movies[movieIndex].name, "Superman")

    XCTAssertFalse(ctx.store.state.movies[movieIndex].favorite)
    await ctx.store.send(.favoriteSwiped(ctx.store.state.movies[movieIndex]))
    await ctx.store.receive(\.toggleFavoriteState) {
      $0.movies[movieIndex] = $0.movies[movieIndex].toggleFavorite()
    }
    XCTAssertTrue(ctx.store.state.movies[movieIndex].favorite)
    await ctx.store.send(.favoriteSwiped(ctx.store.state.movies[movieIndex]))
    await ctx.store.receive(\.toggleFavoriteState) {
      $0.movies[movieIndex] = $0.movies[movieIndex].toggleFavorite()
    }
    XCTAssertFalse(ctx.store.state.movies[movieIndex].favorite)
  }

  @MainActor
  func testRefresh() async throws {
    await ctx.store.send(.refresh)
  }

  @MainActor
  func testTitleSortChanged() async throws {
    XCTAssertEqual(ctx.store.state.actor.name, "Marlon Brando")
    XCTAssertEqual(ctx.store.state.movies.count, 3)

    await ctx.store.send(.titleSortChanged(.reverse)) {
      $0.titleSort = .reverse
      $0.movies = IdentifiedArrayOf<Movie>(uncheckedUniqueElements: $0.movies.elements.reversed())
    }

    await ctx.store.send(.titleSortChanged(.forward)) {
      $0.titleSort = .forward
      $0.movies = IdentifiedArrayOf<Movie>(uncheckedUniqueElements: $0.movies.elements.reversed())
    }

    ctx.store.exhaustivity = .off
    await ctx.store.send(.titleSortChanged(.none)) {
      $0.titleSort = nil
    }

    let titles = Set(ctx.store.state.movies.map(\.name))
    XCTAssertEqual(titles.count, 3)
    for movie in ctx.store.state.movies {
      XCTAssertTrue(titles.contains(movie.name))
    }
  }

  @MainActor
  func testPreviewRender() throws {
    try withDependencies {
      $0.modelContextProvider = ModelContextKey.previewValue
      $0.viewLinkType = .button
    } operation: {
      try withSnapshotTesting(record: .missing) {
        let view = ActorMoviesView.preview
        try assertSnapshot(matching: view)
      }
    }
  }
}
