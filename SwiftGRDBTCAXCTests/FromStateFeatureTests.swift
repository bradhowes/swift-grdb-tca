//import ComposableArchitecture
//import Dependencies
//import Foundation
//import SnapshotTesting
//import SwiftData
//import XCTest
//
//@testable import SwiftGRDBTCA
//
//final class FromStateFeatureTests: XCTestCase {
//  typealias Movies = (Array<SchemaV6.MovieModel>, Array<SchemaV6.Movie>)
//
//  let recording: SnapshotTestingConfiguration.Record = .failed
//  var store: TestStoreOf<FromStateFeature>!
//  var context: ModelContext { store.dependencies.modelContextProvider }
//
//  override func setUpWithError() throws {
//    store = try withDependencies {
//      $0.modelContextProvider = try makeTestContext(mockCount: 4)
//      $0.continuousClock = ImmediateClock()
//    } operation: {
//      TestStore(initialState: FromStateFeature.State()) { FromStateFeature() }
//    }
//  }
//
//  override func tearDownWithError() throws {
//    store.dependencies.modelContextProvider.container.deleteAllData()
//  }
//
//  @MainActor
//  private func fetch() async throws -> Movies {
//    let movieObjs = try context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: ""))
//    let movies = movieObjs.map(\.valueType)
//    await store.send(.onAppear) {
//      $0.movies = .init(uncheckedUniqueElements: movies)
//    }
//    return (movieObjs, movies)
//  }
//
//  @MainActor
//  func testClearScrollToWithNil() async throws {
//    XCTAssertNil(store.state.scrollTo)
//    await store.send(\.clearScrollTo)
//  }
//
//  @MainActor
//  func testAddButtonTapped() async throws {
//    let (_, _) = try await fetch()
//
//    store.exhaustivity = .off
//    await store.send(.addButtonTapped)
//    store.exhaustivity = .off
//
//    // UI should send this after handling non-nil scrollTo
//
//    let movie = store.state.scrollTo
//
//    await store.send(.clearScrollTo) {
//      $0.scrollTo = nil
//    }
//
//    await store.receive(\.highlight) {
//      $0.highlight = movie
//    }
//
//    // UI should send this after handling non-nil highlight
//
//    await store.send(.clearHighlight) {
//      $0.highlight = nil
//    }
//  }
//
//  @MainActor
//  func testDeleteSwiped() async throws {
//    let (_, _) = try await fetch()
//
//    XCTAssertEqual(store.state.movies.count, 4)
//
//    var movie = store.state.movies.randomElement()
//    await store.send(.deleteSwiped(movie!)) {
//      $0.movies = .init(uncheckedUniqueElements: $0.movies.filter { $0 != movie })
//    }
//    XCTAssertEqual(store.state.movies.count, 3)
//
//    movie = store.state.movies.randomElement()
//    await store.send(.deleteSwiped(movie!)) {
//      $0.movies = .init(uncheckedUniqueElements: $0.movies.filter { $0 != movie })
//    }
//    XCTAssertEqual(store.state.movies.count, 2)
//
//    movie = store.state.movies.randomElement()
//    await store.send(.deleteSwiped(movie!)) {
//      $0.movies = .init(uncheckedUniqueElements: $0.movies.filter { $0 != movie })
//    }
//    XCTAssertEqual(store.state.movies.count, 1)
//
//    movie = store.state.movies.randomElement()
//    await store.send(.deleteSwiped(movie!)) {
//      $0.movies = .init(uncheckedUniqueElements: $0.movies.filter { $0 != movie })
//    }
//    XCTAssertTrue(store.state.movies.isEmpty)
//
//    store.exhaustivity = .off(showSkippedAssertions: false)
//    await store.send(.addButtonTapped)
//    store.exhaustivity = .on
//
//    let movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: ""))
//    XCTAssertEqual(movies.count, 1)
//    XCTAssertEqual(movies[0].actors.count, 5)
//    XCTAssertEqual(movies[0].actors[0].movies[0], movies[0])
//  }
//
//  @MainActor
//  func testDetailButtonTapped() async throws {
//    let (_, movies) = try await fetch()
//    await store.send(.detailButtonTapped(movies[0])) {
//      $0.path.append(.showMovieActors(.init(movie: movies[0], nameSort: .forward)))
//    }
//  }
//
//  @MainActor
//  func testFavoriteSwiped() async throws {
//    let (_, movies) = try await fetch()
//    XCTAssertFalse(movies[0].favorite)
//    await store.send(.favoriteSwiped(movies[0]))
//    await store.receive(\.toggleFavoriteState) {
//      $0.movies[0] = $0.movies[0].toggleFavorite()
//    }
//  }
//
//  @MainActor
//  func testMonitorPathChange() async throws {
//    let (movieObjs, movies) = try await fetch()
//
//    await store.send(.detailButtonTapped(movies[0])) {
//      $0.path.append(.showMovieActors(.init(movie: movies[0], nameSort: .forward)))
//    }
//
//    let actorObj = movieObjs[0].actors[0]
//    await store.send(.path(.element(id: 0, action: .showMovieActors(.detailButtonTapped(actorObj.valueType))))) {
//      $0.path.append(.showActorMovies(.init(actor: actorObj.valueType, titleSort: .forward)))
//    }
//
//    await store.send(.path(.element(id: 1, action: .showActorMovies(.detailButtonTapped(movies[0]))))) {
//      $0.path.append(.showMovieActors(.init(movie: movies[0], nameSort: .forward)))
//    }
//
//    await store.send(.path(.element(id: 2, action: .showMovieActors(.detailButtonTapped(actorObj.valueType))))) {
//      $0.path.append(.showActorMovies(.init(actor: actorObj.valueType, titleSort: .forward)))
//    }
//
//    await store.send(.path(.element(id: 3, action: .showActorMovies(.detailButtonTapped(movies[0]))))) {
//      $0.path.append(.showMovieActors(.init(movie: movies[0], nameSort: .forward)))
//    }
//
//    await store.send(.path(.popFrom(id: 4))) { _ = $0.path.popLast() }
//    await store.send(.path(.popFrom(id: 3))) { _ = $0.path.popLast() }
//    await store.send(.path(.popFrom(id: 2))) { _ = $0.path.popLast() }
//    await store.send(.path(.popFrom(id: 1))) { _ = $0.path.popLast() }
//    await store.send(.path(.popFrom(id: 0))) { _ = $0.path.popLast() }
//  }
//
//  @MainActor
//  func testSearching() async throws {
//    let (_, movies) = try await fetch()
//
//    await store.send(.searchButtonTapped(true)) {
//      $0.isSearchFieldPresented = true
//    }
//
//    await store.send(.searchTextChanged("zzz")) {
//      $0.searchText = "zzz"
//      $0.movies = .init()
//    }
//
//    await store.send(.searchTextChanged("zzz")) // No change
//
//    await store.send(.searchTextChanged("the")) {
//      $0.searchText = "the"
//      $0.movies = .init(uncheckedUniqueElements: [movies[1], movies[2]])
//    }
//
//    await store.send(.searchTextChanged("the s")) {
//      $0.searchText = "the s"
//      $0.movies = .init(uncheckedUniqueElements: [movies[2]])
//    }
//
//    await store.send(.searchButtonTapped(false)) {
//      $0.isSearchFieldPresented = false
//      $0.searchText = ""
//      $0.movies = .init(uncheckedUniqueElements: movies)
//    }
//  }
//
//  @MainActor
//  func testTitleSorting() async throws {
//    var (_, movies) = try await fetch()
//
//    await store.send(.titleSortChanged(.reverse)) {
//      $0.titleSort = .reverse
//      $0.movies = .init(uncheckedUniqueElements: movies.reversed())
//    }
//
//    store.exhaustivity = .off
//    await store.send(.titleSortChanged(.none)) {
//      $0.titleSort = .none
//    }
//    store.exhaustivity = .on
//
//    await store.send(.titleSortChanged(.forward)) {
//      $0.titleSort = .forward
//      $0.movies = .init(uncheckedUniqueElements: movies)
//    }
//  }
//
//  @MainActor
//  func testPreviewRenderWithButtons() throws {
//    try withDependencies {
//      $0.modelContextProvider = ModelContextKey.previewValue
//      $0.viewLinkType = .button
//    } operation: {
//      try withSnapshotTesting(record: recording) {
//        let view = FromStateView.previewWithButtons
//        try assertSnapshot(matching: view)
//      }
//    }
//  }
//
//  @MainActor
//  func testPreviewRenderWithLinks() throws {
//    try withDependencies {
//      $0.modelContextProvider = ModelContextKey.previewValue
//      $0.viewLinkType = .navLink
//    } operation: {
//      try withSnapshotTesting(record: recording) {
//        let view = FromStateView.previewWithLinks
//        try assertSnapshot(matching: view)
//      }
//    }
//  }
//
//  @MainActor
//  func testPreviewRenderWithLinksDrillDownMovie() throws {
//    try withDependencies {
//      $0.modelContextProvider = ModelContextKey.previewValue
//      $0.viewLinkType = .navLink
//    } operation: {
//      try withSnapshotTesting(record: recording) {
//        @Dependency(\.modelContextProvider) var context
//        let movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward))
//        let store = Store(initialState: .init(
//          path: StackState<RootFeature.Path.State>(
//            [.showMovieActors(MovieActorsFeature.State(movie: movies[0].valueType))]
//          )
//        )) { FromStateFeature() }
//        let view = FromStateView(store: store)
//          .modelContext(context)
//        try assertSnapshot(matching: view)
//      }
//    }
//  }
//
//  @MainActor
//  func testPreviewRenderWithLinksDrillDownMovieActor() throws {
//    try withDependencies {
//      $0.modelContextProvider = ModelContextKey.previewValue
//      $0.viewLinkType = .navLink
//    } operation: {
//      try withSnapshotTesting(record: recording) {
//        @Dependency(\.modelContextProvider) var context
//        let movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward))
//        let store = Store(initialState: .init(
//          path: StackState<RootFeature.Path.State>(
//            [
//              .showMovieActors(MovieActorsFeature.State(movie: movies[0].valueType)),
//              .showActorMovies(ActorMoviesFeature.State(actor: movies[0].sortedActors(order: .forward)[0].valueType)),
//            ]
//          )
//        )) { FromStateFeature() }
//        let view = FromStateView(store: store)
//          .modelContext(context)
//        try assertSnapshot(matching: view)
//      }
//    }
//  }
//
//  @MainActor
//  func testRootContentViewRender() throws {
//    try withDependencies {
//      $0.modelContextProvider = ModelContextKey.previewValue
//    } operation: {
//      try withSnapshotTesting(record: recording) {
//        let view = RootFeatureView.preview
//        try assertSnapshot(matching: view)
//      }
//    }
//  }
//}
