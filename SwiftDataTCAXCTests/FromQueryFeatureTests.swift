import ComposableArchitecture
import Dependencies
import Foundation
import SnapshotTesting
import SwiftData
import XCTest

@testable import SwiftDataTCA

@MainActor
private final class Context {
  let store: TestStoreOf<FromQueryFeature>

  init(context: ModelContext) throws {
    store = try withDependencies {
      $0.modelContextProvider = context
      $0.continuousClock = ImmediateClock()
    } operation: {
      @Dependency(\.modelContextProvider) var context
      let movies = try context.fetch(FetchDescriptor<MovieModel>())
      return TestStore(initialState: FromQueryFeature.State()) {
        FromQueryFeature()
      }
    }
  }
}

final class FromQueryFeatureTests: XCTestCase {
  typealias Movies = (Array<SchemaV6.MovieModel>, Array<SchemaV6.Movie>)

  private let recording: SnapshotTestingConfiguration.Record = .missing
  private var context: ModelContext!
  private var ctx: Context!

  override func setUp() async throws {
    context = try makeTestContext(mockCount: 3)
    await ctx = try Context(context: context)
  }

  @MainActor
  private func fetch() async throws -> Movies {
    let movieObjs = (try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: "")))
    let movies = movieObjs.map(\.valueType)
    return (movieObjs, movies)
  }

  @MainActor
  func testAddButtonTapped() async throws {
    await ctx.store.send(.addButtonTapped)
    let movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: ""))

    await ctx.store.receive(\.scrollTo) {
      $0.scrollTo = movies[0].valueType
    }

    // UI should send this after handling non-nil scrollTo
    await ctx.store.send(.clearScrollTo) {
      $0.scrollTo = nil
    }

    await ctx.store.receive(\.highlight) {
      $0.highlight = movies[0].valueType
    }

    // UI should send this after handling non-nil highlight
    await ctx.store.send(.clearHighlight) {
      $0.highlight = nil
    }
  }

  @MainActor
  func testClearScrollToWithNil() async throws {
    XCTAssertNil(ctx.store.state.scrollTo)
    await ctx.store.send(\.clearScrollTo)
  }

  @MainActor
  func testDeleteSwiped() async throws {
    var (movieObjs, movies) = try await fetch()

    await ctx.store.send(.deleteSwiped(movies[0]))

    movieObjs = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: ""))
    XCTAssertEqual(movieObjs.count, 2)
  }

  @MainActor
  func testDetailButtonTapped() async throws {
    let (_, movies) = try await fetch()

    await ctx.store.send(.detailButtonTapped(movies[0])) {
      $0.path.append(.showMovieActors(.init(movie: movies[0])))
    }
  }

  @MainActor
  func testFavoriteSwiped() async throws {
    var (movieObjs, movies) = try await fetch()
    await ctx.store.send(.favoriteSwiped(movies[0]))
    await ctx.store.receive(\.toggleFavoriteState)

    movieObjs = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: ""))
    XCTAssertTrue(movieObjs[0].favorite)
  }

  @MainActor
  func testMonitorPathChange() async throws {
    let (movieObjs, movies) = try await fetch()

    await ctx.store.send(.detailButtonTapped(movies[0])) {
      $0.path.append(.showMovieActors(.init(movie: movies[0])))
    }

    let actorObj = movieObjs[0].actors[0]
    await ctx.store.send(.path(.element(id: 0, action: .showMovieActors(.detailButtonTapped(actorObj.valueType))))) {
      $0.path.append(.showActorMovies(.init(actor: actorObj.valueType)))
    }

    await ctx.store.send(.path(.element(id: 1, action: .showActorMovies(.detailButtonTapped(movies[0]))))) {
      $0.path.append(.showMovieActors(.init(movie: movies[0])))
    }

    await ctx.store.send(.path(.element(id: 2, action: .showMovieActors(.detailButtonTapped(actorObj.valueType))))) {
      $0.path.append(.showActorMovies(.init(actor: actorObj.valueType)))
    }

    await ctx.store.send(.path(.element(id: 3, action: .showActorMovies(.detailButtonTapped(movies[0]))))) {
      $0.path.append(.showMovieActors(.init(movie: movies[0])))
    }

    await ctx.store.send(.path(.popFrom(id: 4))) { _ = $0.path.popLast() }
    await ctx.store.send(.path(.popFrom(id: 3))) { _ = $0.path.popLast() }
    await ctx.store.send(.path(.popFrom(id: 2))) { _ = $0.path.popLast() }
    await ctx.store.send(.path(.popFrom(id: 1))) { _ = $0.path.popLast() }
    await ctx.store.send(.path(.popFrom(id: 0))) { _ = $0.path.popLast() }
  }

  @MainActor
  func testSearching() async throws {
    let (_, _) = try await fetch()

    await ctx.store.send(.searchButtonTapped(true)) {
      $0.isSearchFieldPresented = true
    }

    await ctx.store.send(.searchTextChanged("zzz")) {
      $0.searchText = "zzz"
    }

    await ctx.store.send(.searchTextChanged("zzz")) // No change

    await ctx.store.send(.searchTextChanged("the")) {
      $0.searchText = "the"
    }

    await ctx.store.send(.searchTextChanged("the s")) {
      $0.searchText = "the s"
    }

    await ctx.store.send(.searchButtonTapped(false)) {
      $0.isSearchFieldPresented = false
    }
  }

  @MainActor
  func testTitleSorting() async throws {
    await ctx.store.send(.titleSortChanged(.reverse)) {
      $0.titleSort = .reverse
    }

    await ctx.store.send(.titleSortChanged(.none)) {
      $0.titleSort = .none
    }
  }

  @MainActor
  func testPreviewRenderWithButtons() throws {
    try withDependencies {
      $0.modelContextProvider = ModelContextKey.previewValue
      $0.viewLinkType = .button
    } operation: {
      try withSnapshotTesting(record: recording) {
        let view = FromQueryView.previewWithButtons
        try assertSnapshot(matching: view)
      }
    }
  }

  @MainActor
  func testPreviewRenderWithLinks() throws {
    try withDependencies {
      $0.modelContextProvider = ModelContextKey.previewValue
      $0.viewLinkType = .navLink
    } operation: {
      try withSnapshotTesting(record: recording) {
        let view = FromQueryView.previewWithLinks
        try assertSnapshot(matching: view)
      }
    }
  }

  @MainActor
  func testPreviewRenderWithLinksDrillDownMovie() throws {
    try withDependencies {
      $0.modelContextProvider = ModelContextKey.previewValue
      $0.viewLinkType = .navLink
    } operation: {
      try withSnapshotTesting(record: recording) {
        @Dependency(\.modelContextProvider) var context
        let movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward))
        let store = Store(initialState: .init(
          path: StackState<RootFeature.Path.State>(
            [.showMovieActors(MovieActorsFeature.State(movie: movies[0].valueType))]
          )
        )) { FromQueryFeature() }
        let view = FromQueryView(store: store)
          .modelContext(context)
        try assertSnapshot(matching: view)
      }
    }
  }

  @MainActor
  func testPreviewRenderWithLinksDrillDownMovieActor() throws {
    try withDependencies {
      $0.modelContextProvider = ModelContextKey.previewValue
      $0.viewLinkType = .navLink
    } operation: {
      try withSnapshotTesting(record: recording) {
        @Dependency(\.modelContextProvider) var context
        let movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward))
        let store = Store(initialState: .init(
          path: StackState<RootFeature.Path.State>(
            [
              .showMovieActors(MovieActorsFeature.State(movie: movies[0].valueType)),
              .showActorMovies(ActorMoviesFeature.State(actor: movies[0].sortedActors(order: .forward)[0].valueType)),
            ]
          )
        )) { FromQueryFeature() }
        let view = FromQueryView(store: store)
          .modelContext(context)
        try assertSnapshot(matching: view)
      }
    }
  }
}
