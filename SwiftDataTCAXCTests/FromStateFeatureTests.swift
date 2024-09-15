import ComposableArchitecture
import Dependencies
import Foundation
import SnapshotTesting
import SwiftData
import XCTest

@testable import SwiftDataTCA

final class FromStateFeatureTests: XCTestCase {

  var store: TestStoreOf<FromStateFeature>!
  var context: ModelContext { store.dependencies.modelContextProvider }

  override func setUpWithError() throws {
    // isRecording = true
    store = try withDependencies {
      $0.modelContextProvider = try makeTestContext()
      $0.continuousClock = ImmediateClock()
    } operation: {
      TestStore(initialState: FromStateFeature.State()) {
        FromStateFeature()
      }
    }
  }

  override func tearDownWithError() throws {
    store.dependencies.modelContextProvider.container.deleteAllData()
  }

  @MainActor
  func testClearHighlightWithNil() async throws {
    XCTAssertNil(store.state.highlight)
    await store.send(\.clearHighlight)
  }

  @MainActor
  func testClearScrollToWithNil() async throws {
    XCTAssertNil(store.state.scrollTo)
    await store.send(\.clearScrollTo)
  }

  @MainActor
  func testAddButtonTapped() async throws {
    store.exhaustivity = .on
    XCTAssertNil(store.state.scrollTo)
    await store.send(.addButtonTapped)
    let movies = try! context.fetch(ActiveSchema.movieFetchDescriptor())
    XCTAssertEqual(1, movies.count)
    XCTAssertEqual("The Score", movies[0].title)

    await store.receive(\._fetchMovies) {
      $0.movies = movies.map { $0.valueType }
      $0.scrollTo = movies[0].valueType
    }

    // UI should send this after handling non-nil scrollTo

    await store.send(.clearScrollTo) {
      $0.scrollTo = nil
    }

    await store.receive(\.highlight) {
      $0.highlight = movies[0].valueType
    }

    // UI should send this after handling non-nil highlight

    await store.send(.clearHighlight) {
      $0.highlight = nil
    }
  }

  @MainActor
  func testDeleteSwiped() async throws {
    await store.send(.addButtonTapped)
    let movies = (try! context.fetch(ActiveSchema.movieFetchDescriptor())).map { $0.valueType }

    await store.receive(\._fetchMovies) {
      $0.movies = movies
      $0.scrollTo = movies[0]
    }

    await store.send(.deleteSwiped(movies[0]))

    await store.receive(\._fetchMovies) {
      $0.movies = []
    }
  }

  @MainActor
  func testDetailButtonTapped() async throws {
    await store.send(.addButtonTapped)
    let movies = (try! context.fetch(ActiveSchema.movieFetchDescriptor())).map { $0.valueType }
    await store.receive(\._fetchMovies) {
      $0.movies = movies
      $0.scrollTo = movies[0]
    }

    await store.send(.detailButtonTapped(movies[0])) {
      $0.path.append(.showMovieActors(.init(movie: movies[0])))
    }
  }

  @MainActor
  func testMonitorPathChange() async throws {
    await store.send(.addButtonTapped)
    let movieObjs = try! context.fetch(ActiveSchema.movieFetchDescriptor())
    let movies = movieObjs.map { $0.valueType }
    await store.receive(\._fetchMovies) {
      $0.movies = movies
      $0.scrollTo = movies[0]
    }

    await store.send(.detailButtonTapped(movies[0])) {
      $0.path.append(.showMovieActors(.init(movie: movies[0])))
    }

    let actorObj = movieObjs[0].actors[0]
    await store.send(.path(.element(id: 0, action: .showMovieActors(.detailButtonTapped(actorObj.valueType))))) {
      $0.path.append(.showActorMovies(.init(actor: actorObj.valueType)))
    }

    await store.send(.path(.element(id: 1, action: .showActorMovies(.detailButtonTapped(movies[0]))))) {
      $0.path.append(.showMovieActors(.init(movie: movies[0])))
    }

    await store.send(.path(.element(id: 2, action: .showMovieActors(.detailButtonTapped(actorObj.valueType))))) {
      $0.path.append(.showActorMovies(.init(actor: actorObj.valueType)))
    }

    await store.send(.path(.element(id: 3, action: .showActorMovies(.detailButtonTapped(movies[0]))))) {
      $0.path.append(.showMovieActors(.init(movie: movies[0])))
    }

    await store.send(.path(.popFrom(id: 4))) { _ = $0.path.popLast() }
    await store.send(.path(.popFrom(id: 3))) { _ = $0.path.popLast() }
    await store.send(.path(.popFrom(id: 2))) { _ = $0.path.popLast() }
    await store.send(.path(.popFrom(id: 1))) { _ = $0.path.popLast() }
    await store.send(.path(.popFrom(id: 0))) { _ = $0.path.popLast() }
  }

  @MainActor
  func testFavoriteSwiped() async throws {
    var movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, search: ""))
    XCTAssertTrue(movies.isEmpty)

    store.exhaustivity = .off
    await store.send(.addButtonTapped)

    movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, search: ""))
    XCTAssertFalse(movies[0].favorite)
    let movie = movies[0].valueType
    await store.send(.favoriteSwiped(movie))
    await store.receive(\.toggleFavoriteState)
    XCTAssertTrue(movies[0].favorite)
  }

  @MainActor
  func testSearching() async throws {
    await store.send(.addButtonTapped)
    let movieObjs = try! context.fetch(ActiveSchema.movieFetchDescriptor())
    let movies = movieObjs.map { $0.valueType }
    await store.receive(\._fetchMovies) {
      $0.movies = movies
      $0.scrollTo = movies[0]
    }

    await store.send(.searchButtonTapped(true)) {
      $0.isSearchFieldPresented = true
    }

    await store.send(.searchTextChanged("zzz")) {
      $0.searchText = "zzz"
    }

    await store.receive(\._fetchMovies) {
      $0.movies = []
    }

    await store.send(.searchTextChanged("zzz")) // No change

    await store.send(.searchTextChanged("score")) {
      $0.searchText = "score"
    }

    await store.receive(\._fetchMovies) {
      $0.movies = movies
    }

    await store.send(.searchButtonTapped(false)) {
      $0.isSearchFieldPresented = false
    }
  }

  @MainActor
  func testTitleSorting() async throws {
    try Support.generateMocks(context: context, count: 4)
    var movieObjs = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: ""))
    let movies = movieObjs.map { $0.valueType }

    await store.send(._fetchMovies(nil)) {
      $0.movies = movies
    }

    await store.send(.titleSortChanged(.reverse)) {
      $0.titleSort = .reverse
    }

    movieObjs = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .reverse, search: ""))
    await store.receive(\._fetchMovies) {
      $0.movies = movieObjs.map { $0.valueType }
    }

    await store.send(.titleSortChanged(.none)) {
      $0.titleSort = .none
    }

    movieObjs = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, search: ""))
    await store.receive(\._fetchMovies) {
      $0.movies = movieObjs.map { $0.valueType }
    }
  }

  @MainActor
  func testPreviewRender() throws {
    try withDependencies {
      $0.modelContextProvider = ModelContextKey.previewValue
    } operation: {
      try withSnapshotTesting(record: .missing) {
        let view = FromStateView.preview
        try assertSnapshot(matching: view)
      }
    }
  }

  @MainActor
  func testRootContentViewRender() throws {
    try withDependencies {
      $0.modelContextProvider = ModelContextKey.previewValue
    } operation: {
      try withSnapshotTesting(record: .missing) {
        let view = RootFeatureView.preview
        try assertSnapshot(matching: view)
      }
    }
  }
}
