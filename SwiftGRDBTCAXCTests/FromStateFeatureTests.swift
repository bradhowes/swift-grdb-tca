import ComposableArchitecture
import Dependencies
import Foundation
import GRDB
import Models
import SnapshotTesting
import SwiftData
import XCTest

@testable import SwiftGRDBTCA

@MainActor
private final class Context {
  let store: TestStoreOf<FromStateFeature>

  init() throws {
    store = withDependencies {
      $0.defaultDatabase = try! DatabaseQueue.appDatabase(mockCount: 13) // swiftlint:disable:this force_try
      $0.continuousClock = ImmediateClock()
    } operation: {
      TestStore(initialState: FromStateFeature.State()) {
        FromStateFeature()
      }
    }
  }
}

final class FromStateFeatureTests: XCTestCase {
  private var ctx: Context!

  override func setUp() async throws {
    await ctx = try Context()
  }

  @MainActor
  func testClearScrollToWithNil() async throws {
    XCTAssertNil(ctx.store.state.scrollTo)
    await ctx.store.send(\.clearScrollTo)
  }

  @MainActor
  func testAddButtonTapped() async throws {
    @Dependency(\.defaultDatabase) var database

    await ctx.store.send(.addButtonTapped) {
      let added = $0.movies[11]
      $0.scrollTo = added
    }

    let added = ctx.store.state.scrollTo
    await ctx.store.send(.clearScrollTo) {
      $0.scrollTo = nil
    }

    await ctx.store.receive(\.highlight) {
      $0.highlight = added
    }

    await ctx.store.send(.clearHighlight) {
      $0.highlight = nil
    }
  }

  @MainActor
  func testDeleteSwiped() async throws {
    var movie = ctx.store.state.movies[0]
    await ctx.store.send(.deleteSwiped(movie))
    XCTAssertEqual(ctx.store.state.movies.count, 12)

    movie = ctx.store.state.movies[2]
    await ctx.store.send(.deleteSwiped(movie))
    XCTAssertEqual(ctx.store.state.movies.count, 11)
  }

  @MainActor
  func testDetailButtonTapped() async throws {
    let movie = ctx.store.state.movies[0]
    await ctx.store.send(.movieButtonTapped(movie)) {
      $0.path.append(.showMovieActors(.init(movie: movie, nameSort: .forward)))
    }
  }

  @MainActor
  func testFavoriteSwiped() async throws {
    await ctx.store.send(.favoriteSwiped(ctx.store.state.movies[1]))
    await ctx.store.receive(\.toggleFavoriteState)
  }

  @MainActor
  func testMonitorPathChange() async throws {
    let movie = ctx.store.state.movies[0]
    let database = ctx.store.dependencies.defaultDatabase
    let actors = try await database.read { try movie.actors.order(SortOrder.forward.by(Actor.Columns.name)).fetchAll($0) }
    let actor = actors[0]

    await ctx.store.send(.movieButtonTapped(movie)) {
      $0.path.append(.showMovieActors(.init(movie: movie, nameSort: .forward)))
    }

    await ctx.store.send(.path(.element(id: 0, action: .showMovieActors(.detailButtonTapped(actor))))) {
      $0.path.append(.showActorMovies(.init(actor: actor)))
    }

    await ctx.store.send(.path(.element(id: 1, action: .showActorMovies(.detailButtonTapped(movie))))) {
      $0.path.append(.showMovieActors(.init(movie: movie, nameSort: .forward)))
    }

    await ctx.store.send(.path(.element(id: 2, action: .showMovieActors(.detailButtonTapped(actor))))) {
      $0.path.append(.showActorMovies(.init(actor: actor)))
    }

    await ctx.store.send(.path(.element(id: 3, action: .showActorMovies(.detailButtonTapped(movie))))) {
      $0.path.append(.showMovieActors(.init(movie: movie)))
    }

    await ctx.store.send(.path(.popFrom(id: 4))) { _ = $0.path.popLast() }
    await ctx.store.send(.path(.popFrom(id: 3))) { _ = $0.path.popLast() }
    await ctx.store.send(.path(.popFrom(id: 2))) { _ = $0.path.popLast() }
    await ctx.store.send(.path(.popFrom(id: 1))) { _ = $0.path.popLast() }
    await ctx.store.send(.path(.popFrom(id: 0))) { _ = $0.path.popLast() }
  }

  @MainActor
  func testSearching() async throws {
    XCTAssertEqual(ctx.store.state.movies.count, 13)
    await ctx.store.send(.searchButtonTapped(true)) {
      $0.isSearchFieldPresented = true
    }

    await ctx.store.send(.searchTextChanged("zzz")) {
      $0.searchText = "zzz"
    }

    XCTAssertEqual(ctx.store.state.movies.count, 0)

    await ctx.store.send(.searchTextChanged("zzz")) // No change

    await ctx.store.send(.searchTextChanged("g")) {
      $0.searchText = "g"
    }

    XCTAssertEqual(ctx.store.state.movies.count, 2)

    await ctx.store.send(.searchTextChanged("go")) {
      $0.searchText = "go"
    }

    XCTAssertEqual(ctx.store.state.movies.count, 1)
    XCTAssertEqual(ctx.store.state.movies.first?.title, "The Godfather")

    await ctx.store.send(.searchTextChanged("goo")) {
      $0.searchText = "goo"
    }

    XCTAssertEqual(ctx.store.state.movies.count, 0)

    await ctx.store.send(.searchTextChanged("go")) {
      $0.searchText = "go"
    }

    XCTAssertEqual(ctx.store.state.movies.count, 1)

    await ctx.store.send(.searchButtonTapped(false)) {
      $0.isSearchFieldPresented = false
      $0.searchText = ""
    }

    XCTAssertEqual(ctx.store.state.movies.count, 13)
  }

  @MainActor
  func testTitleSorting() async throws {
    let database = ctx.store.dependencies.defaultDatabase

    await ctx.store.send(.titleSortChanged(.reverse)) {
      $0.titleSort = .reverse
    }

    var movies = database.movies(ordering: .reverse)
    XCTAssertEqual(ctx.store.state.movies, movies)

    await ctx.store.send(.titleSortChanged(.none)) {
      $0.titleSort = .none
    }

    movies = database.movies(ordering: nil)
    XCTAssertEqual(ctx.store.state.movies, movies)

    await ctx.store.send(.titleSortChanged(.forward)) {
      $0.titleSort = .forward
    }

    movies = database.movies(ordering: .forward)
    XCTAssertEqual(ctx.store.state.movies, movies)
  }

  @MainActor
  func testPreviewRenderWithButtons() throws {
    withSnapshotTesting(record: .missing) {
      let view = FromStateView.previewWithButtons
      assertSnapshot(of: view, as: .image)
    }
  }
}
