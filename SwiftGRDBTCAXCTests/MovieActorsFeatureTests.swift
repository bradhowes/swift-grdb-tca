import ComposableArchitecture
import Dependencies
import Foundation
import GRDB
import Models
import SnapshotTesting
import XCTest

@testable import SwiftGRDBTCA

@MainActor
private final class Context {
  let store: TestStoreOf<MovieActorsFeature>

  init() throws {
    store = try withDependencies {
      $0.defaultDatabase = try! appDatabase(rowCount: 13) // swiftlint:disable:this force_try
      $0.continuousClock = ImmediateClock()
    } operation: {
      @Dependency(\.defaultDatabase) var database
      let movies = try database.read {
        try Movie.all.fetchAll($0)
      }
      return TestStore(initialState: MovieActorsFeature.State(movie: movies[0])) {
        MovieActorsFeature()
      }
    }
  }
}

final class MovieActorsFeatureTests: XCTestCase {
  private var ctx: Context!

  override func setUp() async throws {
    await ctx = try Context()
  }

  @MainActor
  func testDetailButtonTapped() async throws {
    await ctx.store.send(.detailButtonTapped(ctx.store.state.actors[0]))
  }

  @MainActor
  func testFavoriteTapped() async throws {
    XCTAssertFalse(ctx.store.state.movie.favorite)
    await ctx.store.send(.favoriteTapped) {
      $0.animateButton = true
      $0.movie.favorite.toggle()
    }
    XCTAssertTrue(ctx.store.state.movie.favorite)
    await ctx.store.send(.favoriteTapped) {
      $0.animateButton = false
      $0.movie.favorite.toggle()
    }
    XCTAssertFalse(ctx.store.state.movie.favorite)
  }

  @MainActor
  func testNameSortChanged() async throws {
    let database = ctx.store.dependencies.defaultDatabase
    XCTAssertEqual(ctx.store.state.movie.title, "The Score")
    XCTAssertEqual(ctx.store.state.actors.count, 5)

    await ctx.store.send(.nameSortChanged(.reverse)) {
      $0.nameSort = .reverse
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    let movie = ctx.store.state.movie
    var actors = try await database.read { db in
      try MovieActorsQuery(movie: movie, ordering: .reverse).fetch(db)
    }
    XCTAssertEqual(ctx.store.state.actors, actors)

    await ctx.store.send(.nameSortChanged(.forward)) {
      $0.nameSort = .forward
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    actors = try await database.read { db in
      try MovieActorsQuery(movie: movie, ordering: .forward).fetch(db)
    }
    XCTAssertEqual(ctx.store.state.actors, actors)

    ctx.store.exhaustivity = .off
    await ctx.store.send(.nameSortChanged(.none)) {
      $0.nameSort = .none
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    let names = Set(ctx.store.state.actors.map(\.name))
    XCTAssertEqual(names.count, 5)

    XCTAssertTrue(names.contains(ctx.store.state.actors[0].name))
    XCTAssertTrue(names.contains(ctx.store.state.actors[1].name))
    XCTAssertTrue(names.contains(ctx.store.state.actors[2].name))
    XCTAssertTrue(names.contains(ctx.store.state.actors[3].name))
    XCTAssertTrue(names.contains(ctx.store.state.actors[4].name))
  }

  @MainActor
  func testSearching() async throws {
    XCTAssertEqual(ctx.store.state.actors.count, 5)
    for each in ctx.store.state.actors {
      print(each.name)
    }
    await ctx.store.send(.searchButtonTapped(true)) {
      $0.isSearchFieldPresented = true
    }

    await ctx.store.send(.searchTextChanged("zzz")) {
      $0.searchText = "zzz"
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    XCTAssertEqual(ctx.store.state.actors.count, 0)

    await ctx.store.send(.searchTextChanged("zz")) {
      $0.searchText = "zz"
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    await ctx.store.send(.searchTextChanged("n")) {
      $0.searchText = "n"
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))

    XCTAssertEqual(ctx.store.state.actors.count, 2)
    let names = ctx.store.state.actors.map(\.name)
    XCTAssertTrue(names.contains("Edward Norton"))
    XCTAssertTrue(names.contains("Robert De Niro"))

    await ctx.store.send(.searchTextChanged("no")) {
      $0.searchText = "no"
    }

    await ctx.store.receive(\.queryUpdated, timeout: .seconds(10))
    XCTAssertEqual(ctx.store.state.actors.count, 1)
    XCTAssertTrue(ctx.store.state.actors[0].name == "Edward Norton")
  }

  @MainActor
  func testRefresh() async throws {
    await ctx.store.send(.refresh)
  }

  @MainActor
  func testPreviewRenderWithButtons() throws {
    withSnapshotTesting(record: .failed) {
      let view = MovieActorsView.preview
      TestSupport.assertSnapshot(matching: view)
    }
  }
}
