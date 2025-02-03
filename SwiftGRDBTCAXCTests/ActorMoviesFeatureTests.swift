import ComposableArchitecture
import Dependencies
import Foundation
import IdentifiedCollections
import GRDB
import Models
import SnapshotTesting
import SwiftUI
import XCTest

@testable import SwiftGRDBTCA

@MainActor
private final class Context {
  let store: TestStoreOf<ActorMoviesFeature>

  init() throws {
    store = withDependencies {
      $0.defaultDatabase = try! DatabaseQueue.appDatabase(mockCount: 13) // swiftlint:disable:this force_try
      $0.continuousClock = ImmediateClock()
    } operation: {
      @Dependency(\.defaultDatabase) var database
      let movies = database.movies()
      let actors = database.actors(for: movies[0])
      return TestStore(initialState: ActorMoviesFeature.State(actor: actors[1])) {
        ActorMoviesFeature()
      }
    }
  }
}

extension XCTestCase {
  var isOnGithub: Bool {
    ProcessInfo.processInfo.environment["CFFIXED_USER_HOME"]?.contains("/Users/runner/Library") ?? false
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
    XCTAssertEqual(ctx.store.state.movies[movieIndex].title, "The Godfather")

    XCTAssertFalse(ctx.store.state.movies[movieIndex].favorite)
    await ctx.store.send(.favoriteSwiped(ctx.store.state.movies[movieIndex]))
    await ctx.store.receive(\.toggleFavoriteState) {
      $0.movies[movieIndex].favorite.toggle()
    }
    XCTAssertTrue(ctx.store.state.movies[movieIndex].favorite)
    await ctx.store.send(.favoriteSwiped(ctx.store.state.movies[movieIndex]))
    await ctx.store.receive(\.toggleFavoriteState) {
      $0.movies[movieIndex].favorite.toggle()
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
    XCTAssertEqual(ctx.store.state.movies.count, 8)

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
      $0.titleSort = .none
    }

    let titles = Set(ctx.store.state.movies.map(\.title))
    XCTAssertEqual(titles.count, 8)
    for movie in ctx.store.state.movies {
      XCTAssertTrue(titles.contains(movie.title))
    }
  }

  @MainActor
  func testToggleFavoriteState() async throws {
    await ctx.store.send(.toggleFavoriteState(ctx.store.state.movies[0])) {
      $0.movies[0].favorite.toggle()
    }
  }

  @MainActor
  func testPreviewRender() throws {
    guard !isOnGithub else {
      _ = XCTSkip("Not working on Github")
      return
    }
    withSnapshotTesting(record: .failed) {
      let view = ActorMoviesView.preview
      assertSnapshot(of: view, as: .image)
    }
  }
}
