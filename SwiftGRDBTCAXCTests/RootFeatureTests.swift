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
  let store: TestStoreOf<RootFeature>

  init() throws {
    store = withDependencies {
      $0.defaultDatabase = try! appDatabase(rowCount: 13) // swiftlint:disable:this force_try
      $0.continuousClock = ImmediateClock()
    } operation: {
      TestStore(initialState: RootFeature.State()) {
        RootFeature()
      }
    }
  }
}

final class RootFeatureTests: XCTestCase {
  private var ctx: Context!

  override func setUp() async throws {
    await ctx = try Context()
  }

  @MainActor
  func testAddButtonTapped() async throws {
    @Dependency(\.defaultDatabase) var database

    await ctx.store.send(.addButtonTapped)

    let added = ctx.store.state.movies[11]
    await ctx.store.receive(\.scrollToMovie) {
      $0.scrollTo = added
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
#if os(iOS)
    await ctx.store.receive(\.toggleFavoriteState)
#endif
  }

  @MainActor
  func testMonitorPathChange() async throws {
    let movie = ctx.store.state.movies[0]
    let database = ctx.store.dependencies.defaultDatabase
    let actors = try await database.read { try MovieActorsQuery(movie: movie, ordering: SortOrder.forward).fetch($0) }
    let actor = actors[0]
    print("actor:", actor)

    await ctx.store.send(.movieButtonTapped(movie)) {
      $0.path.append(.showMovieActors(.init(movie: movie, nameSort: .forward)))
    }

    await ctx.store.send(.path(.element(id: 0, action: .showMovieActors(.detailButtonTapped(actor))))) {
      $0.path.append(.showActorMovies(.init(actor: actor, titleSort: .forward)))
    }

    await ctx.store.send(.path(.element(id: 1, action: .showActorMovies(.detailButtonTapped(movie))))) {
      $0.path.append(.showMovieActors(.init(movie: movie, nameSort: .forward)))
    }

    XCTAssertEqual(ctx.store.state.path.count, 3)
  }

  @MainActor
  func testSearching() async throws {
    XCTAssertEqual(ctx.store.state.movies.count, 13)
    for m in ctx.store.state.movies {
      print("-", m.title)
    }

    await ctx.store.send(.searchButtonTapped(true)) {
      $0.isSearchFieldPresented = true
    }

    await ctx.store.send(.searchTextChanged("zzz")) {
      $0.searchText = "zzz"
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    XCTAssertEqual(ctx.store.state.movies.count, 0)

    await ctx.store.send(.searchTextChanged("zzz")) // No change


    await ctx.store.send(.searchTextChanged("s")) {
      $0.searchText = "s"
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    XCTAssertEqual(ctx.store.state.movies.count, 10)
    for m in ctx.store.state.movies {
      print("+", m.title)
    }

    await ctx.store.send(.searchTextChanged("sc")) {
      $0.searchText = "sc"
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    XCTAssertEqual(ctx.store.state.movies.count, 1)

    XCTAssertEqual(ctx.store.state.movies.first?.title, "The Score")

    await ctx.store.send(.searchTextChanged("goo")) {
      $0.searchText = "goo"
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    XCTAssertEqual(ctx.store.state.movies.count, 0)

    await ctx.store.send(.searchTextChanged("go")) {
      $0.searchText = "go"
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    XCTAssertEqual(ctx.store.state.movies.count, 1)

    await ctx.store.send(.searchButtonTapped(false)) {
      $0.isSearchFieldPresented = false
      $0.searchText = ""
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))
    XCTAssertEqual(ctx.store.state.movies.count, 13)
  }

  @MainActor
  func testTitleSorting() async throws {
    let database = ctx.store.dependencies.defaultDatabase

    await ctx.store.send(.titleSortChanged(.reverse)) {
      $0.titleSort = .reverse
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    var movies = try await database.read { try AllMoviesQuery(ordering: .reverse).fetch($0) }
    XCTAssertEqual(ctx.store.state.movies, movies)

    await ctx.store.send(.titleSortChanged(.none)) {
      $0.titleSort = .none
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    movies = try await database.read { try AllMoviesQuery(ordering: nil).fetch($0) }
    XCTAssertEqual(ctx.store.state.movies, movies)

    await ctx.store.send(.titleSortChanged(.forward)) {
      $0.titleSort = .forward
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    movies = try await database.read { try AllMoviesQuery(ordering: .forward).fetch($0) }
    XCTAssertEqual(ctx.store.state.movies, movies)
  }

  @MainActor
  func testPreviewRenderWithButtons() throws {
    withSnapshotTesting(record: .failed) {
      let view = RootView.previewWithButtons
      TestSupport.assertSnapshot(matching: view)
    }
  }
}
