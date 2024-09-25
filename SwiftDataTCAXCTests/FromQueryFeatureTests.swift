import ComposableArchitecture
import Dependencies
import Foundation
import SnapshotTesting
import SwiftData
import XCTest

@testable import SwiftDataTCA

final class FromQueryFeatureTests: XCTestCase {
  typealias Movies = (Array<SchemaV6.MovieModel>, Array<SchemaV6.Movie>)

  let recording: SnapshotTestingConfiguration.Record = .failed
  var store: TestStore<FromQueryFeature.State, FromQueryFeature.Action>!
  var context: ModelContext { store.dependencies.modelContextProvider }

  override func setUpWithError() throws {
    store = try withDependencies {
      $0.modelContextProvider = try makeTestContext(mockCount: 4)
      $0.continuousClock = ImmediateClock()
    } operation: {
      TestStore(initialState: FromQueryFeature.State()) { FromQueryFeature() }
    }
  }
  
  override func tearDownWithError() throws {
    store.dependencies.modelContextProvider.container.deleteAllData()
  }
  
  @MainActor
  private func fetch() async throws -> Movies {
    let movieObjs = (try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: "")))
    let movies = movieObjs.map(\.valueType)
    return (movieObjs, movies)
  }

  @MainActor
  func testAddButtonTapped() async throws {
    await store.send(.addButtonTapped)
    let movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: ""))

    await store.receive(\.scrollTo) {
      $0.scrollTo = movies[1].valueType
    }

    // UI should send this after handling non-nil scrollTo

    await store.send(.clearScrollTo) {
      $0.scrollTo = nil
    }

    await store.receive(\.highlight) {
      $0.highlight = movies[1].valueType
    }

    // UI should send this after handling non-nil highlight

    await store.send(.clearHighlight) {
      $0.highlight = nil
    }
  }
  
  @MainActor
  func testClearScrollToWithNil() async throws {
    XCTAssertNil(store.state.scrollTo)
    await store.send(\.clearScrollTo)
  }

  @MainActor
  func testDeleteSwiped() async throws {
    var (movieObjs, movies) = try await fetch()

    await store.send(.deleteSwiped(movies[0]))

    movieObjs = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: ""))
    XCTAssertEqual(movieObjs.count, 3)
  }

  @MainActor
  func testDetailButtonTapped() async throws {
    let (_, movies) = try await fetch()

    await store.send(.detailButtonTapped(movies[0])) {
      $0.path.append(.showMovieActors(.init(movie: movies[0])))
    }
  }

  @MainActor
  func testFavoriteSwiped() async throws {
    var (movieObjs, movies) = try await fetch()
    await store.send(.favoriteSwiped(movies[0]))
    await store.receive(\.toggleFavoriteState)

    movieObjs = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: ""))
    XCTAssertTrue(movieObjs[0].favorite)
  }

  @MainActor
  func testMonitorPathChange() async throws {
    let (movieObjs, movies) = try await fetch()

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
  func testSearching() async throws {
    let (_, _) = try await fetch()

    await store.send(.searchButtonTapped(true)) {
      $0.isSearchFieldPresented = true
    }

    await store.send(.searchTextChanged("zzz")) {
      $0.searchText = "zzz"
    }

    await store.send(.searchTextChanged("zzz")) // No change

    await store.send(.searchTextChanged("the")) {
      $0.searchText = "the"
    }

    await store.send(.searchTextChanged("the s")) {
      $0.searchText = "the s"
    }

    await store.send(.searchButtonTapped(false)) {
      $0.isSearchFieldPresented = false
    }
  }

  @MainActor
  func testTitleSorting() async throws {
    await store.send(.titleSortChanged(.reverse)) {
      $0.titleSort = .reverse
    }

    await store.send(.titleSortChanged(.none)) {
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

}
