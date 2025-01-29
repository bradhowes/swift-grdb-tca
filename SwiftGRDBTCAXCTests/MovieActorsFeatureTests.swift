//import ComposableArchitecture
//import Dependencies
//import Foundation
//import SnapshotTesting
//import SwiftData
//import XCTest
//
//@testable import SwiftGRDBTCA
//
//
//@MainActor
//private final class Context {
//  let store: TestStoreOf<MovieActorsFeature>
//
//  init() throws {
//    store = try withDependencies {
//      $0.modelContextProvider = try makeTestContext(mockCount: 3)
//      $0.continuousClock = ImmediateClock()
//    } operation: {
//      @Dependency(\.modelContextProvider) var context
//      let movies = try context.fetch(FetchDescriptor<MovieModel>())
//      return TestStore(initialState: MovieActorsFeature.State(movie: movies[0].valueType)) {
//        MovieActorsFeature()
//      }
//    }
//  }
//}
//
//final class MovieActorsFeatureTests: XCTestCase {
//
//  private var ctx: Context!
//
//  override func setUp() async throws {
//    await ctx = try Context()
//  }
//
//  @MainActor
//  func testDetailButtonTapped() async throws {
//    await ctx.store.send(.detailButtonTapped(ctx.store.state.actors[0]))
//  }
//
//  @MainActor
//  func testFavoriteTapped() async throws {
//    XCTAssertTrue(ctx.store.state.movie.favorite)
//    await ctx.store.send(.favoriteTapped) {
//      $0.movie = $0.movie.toggleFavorite()
//    }
//    XCTAssertFalse(ctx.store.state.movie.favorite)
//    await ctx.store.send(.favoriteTapped) {
//      $0.movie = $0.movie.toggleFavorite()
//      $0.animateButton = true
//    }
//    XCTAssertTrue(ctx.store.state.movie.favorite)
//  }
//
//  @MainActor
//  func testNameSortChanged() async throws {
//    XCTAssertEqual(ctx.store.state.movie.name, "The Score")
//    XCTAssertEqual(ctx.store.state.actors.count, 5)
//
//    await ctx.store.send(.nameSortChanged(.reverse)) {
//      $0.nameSort = .reverse
//      $0.actors = IdentifiedArrayOf<Actor>(uncheckedUniqueElements: $0.actors.elements.reversed())
//    }
//
//    await ctx.store.send(.nameSortChanged(.forward)) {
//      $0.nameSort = .forward
//      $0.actors = IdentifiedArrayOf<Actor>(uncheckedUniqueElements: $0.actors.elements.reversed())
//    }
//
//    ctx.store.exhaustivity = .off
//    await ctx.store.send(.nameSortChanged(.none)) {
//      $0.nameSort = nil
//    }
//
//    let names = Set(ctx.store.state.actors.map(\.name))
//    XCTAssertEqual(names.count, 5)
//
//    XCTAssertTrue(names.contains(ctx.store.state.actors[0].name))
//    XCTAssertTrue(names.contains(ctx.store.state.actors[1].name))
//    XCTAssertTrue(names.contains(ctx.store.state.actors[2].name))
//    XCTAssertTrue(names.contains(ctx.store.state.actors[3].name))
//    XCTAssertTrue(names.contains(ctx.store.state.actors[4].name))
//  }
//
//  @MainActor
//  func testRefresh() async throws {
//    await ctx.store.send(.refresh)
//  }
//
//  @MainActor
//  func testPreviewRenderWithButtons() throws {
//    try withDependencies {
//      $0.modelContextProvider = ModelContextKey.previewValue
//      $0.viewLinkType = LinkKind.button
//    } operation: {
//      try withSnapshotTesting(record: .missing) {
//        let view = MovieActorsView.preview
//        try assertSnapshot(matching: view)
//      }
//    }
//  }
//}
