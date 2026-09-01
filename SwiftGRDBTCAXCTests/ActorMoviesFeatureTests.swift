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
    store = try withDependencies {
      $0.defaultDatabase = try! appDatabase(rowCount: 13) // swiftlint:disable:this force_try
      $0.continuousClock = ImmediateClock()
    } operation: {
      @Dependency(\.defaultDatabase) var database
      let actors = try database.read {
        try Actor.all.fetchAll($0)
      }
      return TestStore(initialState: ActorMoviesFeature.State(actor: actors[2])) {
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
//#if os(iOS)
//    await ctx.store.receive(\.toggleFavoriteState)
//#endif
//    XCTAssertTrue(ctx.store.state.movies[movieIndex].favorite)
//    await ctx.store.send(.favoriteSwiped(ctx.store.state.movies[movieIndex]))
//#if os(iOS)
//    await ctx.store.receive(\.toggleFavoriteState)
//#endif
//    XCTAssertFalse(ctx.store.state.movies[movieIndex].favorite)
  }

  @MainActor
  func testTitleSortChanged() async throws {
    XCTAssertEqual(ctx.store.state.actor.name, "Marlon Brando")
    XCTAssertEqual(ctx.store.state.movies.count, 8)

    await ctx.store.send(.titleSortChanged(.reverse)) {
      $0.titleSort = .reverse
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    let actor = ctx.store.state.actor
    var movies = try await ctx.store.dependencies.defaultDatabase.read {
      try ActorMoviesQuery(actor: actor, ordering: .reverse).fetch($0)
    }

    XCTAssertEqual(ctx.store.state.movies, movies)

    await ctx.store.send(.titleSortChanged(.forward)) {
      $0.titleSort = .forward
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    movies = try await ctx.store.dependencies.defaultDatabase.read {
      try ActorMoviesQuery(actor: actor, ordering: .forward).fetch($0)
    }
    XCTAssertEqual(ctx.store.state.movies, movies)

    await ctx.store.send(.titleSortChanged(.none)) {
      $0.titleSort = .none
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))
  }

  @MainActor
  func testSearching() async throws {
    XCTAssertEqual(ctx.store.state.movies.count, 8)
    for each in ctx.store.state.movies {
      print(each.title)
    }

    await ctx.store.send(.searchButtonTapped(true)) {
      $0.isSearchFieldPresented = true
    }

    await ctx.store.send(.searchTextChanged("the")) {
      $0.searchText = "the"
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    XCTAssertEqual(ctx.store.state.movies.count, 4)

    await ctx.store.send(.searchTextChanged("the w")) {
      $0.searchText = "the w"
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    XCTAssertEqual(ctx.store.state.movies.count, 1)
    XCTAssertEqual(ctx.store.state.movies[0].title, "On the Waterfront")

    await ctx.store.send(.searchTextChanged("the g")) {
      $0.searchText = "the g"
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    XCTAssertEqual(ctx.store.state.movies.count, 1)
    XCTAssertEqual(ctx.store.state.movies[0].title, "The Godfather")
  }

  @MainActor
  func testToggleFavoriteState() async throws {
//    XCTAssertFalse(ctx.store.state.movies[0].favorite)
//    await ctx.store.send(.toggleFavoriteState(ctx.store.state.movies[0]))
//    XCTAssertTrue(ctx.store.state.movies[0].favorite)
  }

  @MainActor
  func testPreviewRender() throws {
    withSnapshotTesting(record: .failed) {
      let view = ActorMoviesView.preview
      TestSupport.assertSnapshot(matching: view)
    }
  }
}
