import ComposableArchitecture
import Dependencies
import Foundation
import SnapshotTesting
import SwiftData
import XCTest

@testable import SwiftDataTCA

final class MovieActorsFeatureTests: XCTestCase {
  var context: ModelContext!
  var movie: Movie!

  override func setUpWithError() throws {
    let schema = Schema(versionedSchema: ActiveSchema.self)
    let config = ModelConfiguration("ActiveSchema", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    context = ModelContext(container)
    ActiveSchema.makeMock(context: context, entry: ("This is a Movie", ["Actor 1", "Actor 2"]))
    ActiveSchema.makeMock(context: context, entry: ("Another Movie", ["Actor 1", "Actor 2", "Actor 3"]))
    try! context.save()
    let movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, searchString: ""))
    movie = movies[0]
  }

  override func tearDownWithError() throws {
  }

  @MainActor
  func testActorSelected() async throws {
    let store = TestStore(initialState: MovieActorsFeature.State(movie: movie)) {
      MovieActorsFeature()
    }
    XCTAssertEqual(movie.title, "Another Movie")
    XCTAssertEqual(movie.actors.count, 3)
    await store.send(.actorSelected(movie.actors[1])) // No state change for this
  }

  @MainActor
  func testNameSortChanged() async throws {
    let store = TestStore(initialState: MovieActorsFeature.State(movie: movie, nameSort: .forward)) {
      MovieActorsFeature()
    }

    XCTAssertEqual(movie.title, "Another Movie")
    XCTAssertEqual(movie.actors.count, 3)

    await store.send(.nameSortChanged(.reverse)) {
      $0.nameSort = .reverse
      XCTAssertEqual($0.actors[0].name, "Actor 3")
      XCTAssertEqual($0.actors[1].name, "Actor 2")
      XCTAssertEqual($0.actors[2].name, "Actor 1")
    }

    await store.send(.nameSortChanged(.forward)) {
      $0.nameSort = .forward
      XCTAssertEqual($0.actors[0].name, "Actor 1")
      XCTAssertEqual($0.actors[1].name, "Actor 2")
      XCTAssertEqual($0.actors[2].name, "Actor 3")
    }

    await store.send(.nameSortChanged(.none)) {
      $0.nameSort = nil
      XCTAssertTrue($0.actors[0].name == "Actor 1" || $0.actors[0].name == "Actor 2" || $0.actors[0].name == "Actor 3")
      XCTAssertTrue($0.actors[1].name == "Actor 1" || $0.actors[1].name == "Actor 2" || $0.actors[1].name == "Actor 3")
      XCTAssertTrue($0.actors[2].name == "Actor 1" || $0.actors[2].name == "Actor 2" || $0.actors[2].name == "Actor 3")
    }
  }

  @MainActor
  func testFavoriteTapped() async throws {
    let store = TestStore(initialState: MovieActorsFeature.State(movie: movie)) {
      MovieActorsFeature()
    }

    XCTAssertFalse(movie.favorite)

    await store.send(.favoriteTapped)
    XCTAssertTrue(movie.favorite)

    await store.send(.favoriteTapped)
    XCTAssertFalse(movie.favorite)
  }

  @MainActor
  func testPreviewRender() {
    let view = MovieActorsView.preview
    assertSnapshot(of: view, as: .image)
  }
}

#if hasFeature(RetroactiveAttribute)
extension MovieActorsFeature.State: @retroactive Equatable {
  public static func == (lhs: MovieActorsFeature.State, rhs: MovieActorsFeature.State) -> Bool {
    lhs.movie == rhs.movie &&
    lhs.nameSort == rhs.nameSort
  }
}
#else
extension MovieActorsFeature.State: Equatable {
  public static func == (lhs: MovieActorsFeature.State, rhs: MovieActorsFeature.State) -> Bool {
    lhs.movie == rhs.movie &&
    lhs.nameSort == rhs.nameSort
  }
}
#endif
