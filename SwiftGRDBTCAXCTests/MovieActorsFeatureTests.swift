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
    store = withDependencies {
      $0.defaultDatabase = try! DatabaseQueue.appDatabase(mockCount: 13) // swiftlint:disable:this force_try
      $0.continuousClock = ImmediateClock()
    } operation: {
      @Dependency(\.defaultDatabase) var database
      let movies = database.movies()
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
      $0.movie.favorite.toggle()
      $0.animateButton = true
    }
    XCTAssertFalse(ctx.store.state.movie.favorite)
  }

  @MainActor
  func testNameSortChanged() async throws {
    XCTAssertEqual(ctx.store.state.movie.title, "Apocalypse Now")
    XCTAssertEqual(ctx.store.state.actors.count, 5)

    await ctx.store.send(.nameSortChanged(.reverse)) {
      $0.nameSort = .reverse
      $0.actors = IdentifiedArrayOf<Actor>(uncheckedUniqueElements: $0.actors.elements.reversed())
    }

    await ctx.store.send(.nameSortChanged(.forward)) {
      $0.nameSort = .forward
      $0.actors = IdentifiedArrayOf<Actor>(uncheckedUniqueElements: $0.actors.elements.reversed())
    }

    ctx.store.exhaustivity = .off
    await ctx.store.send(.nameSortChanged(.none)) {
      $0.nameSort = .none
    }

    let names = Set(ctx.store.state.actors.map(\.name))
    XCTAssertEqual(names.count, 5)

    XCTAssertTrue(names.contains(ctx.store.state.actors[0].name))
    XCTAssertTrue(names.contains(ctx.store.state.actors[1].name))
    XCTAssertTrue(names.contains(ctx.store.state.actors[2].name))
    XCTAssertTrue(names.contains(ctx.store.state.actors[3].name))
    XCTAssertTrue(names.contains(ctx.store.state.actors[4].name))
  }

  @MainActor
  func testRefresh() async throws {
    await ctx.store.send(.refresh)
  }

  @MainActor
  func testPreviewRenderWithButtons() throws {
    withSnapshotTesting(record: .failed) {
      let view = MovieActorsView.preview
      assertSnapshot(of: view, as: .image)
    }
  }
}
