import ComposableArchitecture
import Dependencies
import Foundation
import SnapshotTesting
import SwiftData
import XCTest

@testable import SwiftDataTCA

final class FromStateFeatureTests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
    @Dependency(\.modelContextProvider.container) var container
    container.deleteAllData()
  }

  @MainActor
  func testFromStateAddButtonTapped() async throws {
    let store = TestStore(initialState: FromStateFeature.State()) {
      FromStateFeature()
    } withDependencies: {
      $0.withRandomNumberGenerator = .init(LCRNG(seed: 0))
      $0.database.add = {
        @Dependency(\.modelContextProvider.context) var context
        ActiveSchema.makeMock(context: context, entry: Support.mockMovieEntry)
      }
      $0.database.fetchMovies = { descriptor in
        @Dependency(\.modelContextProvider.context) var context
        return (try? context.fetch(descriptor)) ?? []
      }
      $0.database.save = {
        @Dependency(\.modelContextProvider.context) var context
        try? context.save()
      }
    }

    XCTAssertTrue(store.state.movies.isEmpty)

    store.exhaustivity = .off
    await store.send(.addButtonTapped)
    await store.receive(\._fetchMovies)

    XCTAssertEqual(1, store.state.movies.count)
    XCTAssertEqual("The Score", store.state.movies[0].title)
  }

  @MainActor
  func testFromStateDeleteSwiped() async throws {
    let store = TestStore(initialState: FromStateFeature.State()) {
      FromStateFeature()
    } withDependencies: {
      $0.withRandomNumberGenerator = .init(LCRNG(seed: 0))
      $0.database.add = {
        @Dependency(\.modelContextProvider.context) var context
        ActiveSchema.makeMock(context: context, entry: Support.mockMovieEntry)
      }
      $0.database.delete = { movie in
        @Dependency(\.modelContextProvider.context) var context
        context.delete(movie)
      }
      $0.database.fetchMovies = { descriptor in
        @Dependency(\.modelContextProvider.context) var context
        return (try? context.fetch(descriptor)) ?? []
      }
      $0.database.save = {
        @Dependency(\.modelContextProvider.context) var context
        try? context.save()
      }
    }

    XCTAssertTrue(store.state.movies.isEmpty)

    store.exhaustivity = .off
    await store.send(.addButtonTapped)
    await store.receive(\._fetchMovies)

    XCTAssertEqual(1, store.state.movies.count)
    XCTAssertEqual("The Score", store.state.movies[0].title)

    await store.send(.deleteSwiped(store.state.movies[0]))
    await store.receive(\._fetchMovies)

    XCTAssertEqual(0, store.state.movies.count)
  }

  @MainActor
  func testFromStateFavoriteSwiped() async throws {
    let store = TestStore(initialState: FromStateFeature.State()) {
      FromStateFeature()
    } withDependencies: {
      $0.withRandomNumberGenerator = .init(LCRNG(seed: 0))
      $0.database.add = {
        @Dependency(\.modelContextProvider.context) var context
        ActiveSchema.makeMock(context: context, entry: Support.mockMovieEntry)
      }
      $0.database.fetchMovies = { descriptor in
        @Dependency(\.modelContextProvider.context) var context
        return (try? context.fetch(descriptor)) ?? []
      }
      $0.database.save = {
        @Dependency(\.modelContextProvider.context) var context
        try? context.save()
      }
    }

    XCTAssertTrue(store.state.movies.isEmpty)

    store.exhaustivity = .off
    await store.send(.addButtonTapped)
    await store.receive(\._fetchMovies)

    XCTAssertEqual(1, store.state.movies.count)
    XCTAssertEqual("The Score", store.state.movies[0].title)
    XCTAssertFalse(store.state.movies[0].favorite)

    await store.send(.favoriteSwiped(store.state.movies[0]))

    XCTAssertTrue(store.state.movies[0].favorite)
  }

  @MainActor
  func testPreviewRender() throws {
    let view = FromStateView.preview
    try assertSnapshot(matching: view)
  }

  @MainActor
  func testMockMovieEntry() async {
    withDependencies {
      $0.withRandomNumberGenerator = .init(LCRNG(seed: 0))
    } operation: {
      XCTAssertEqual(Support.mockMovieEntry.0, "The Score")
      XCTAssertEqual(Support.mockMovieEntry.0, "Salt")
    }
  }

  private struct LCRNG: RandomNumberGenerator {
    var seed: UInt64
    mutating func next() -> UInt64 {
      self.seed = 2_862_933_555_777_941_757 &* self.seed &+ 3_037_000_493
      return self.seed
    }
  }
}

#if hasFeature(RetroactiveAttribute)
extension FromStateFeature.State: @retroactive Equatable {
  public static func == (lhs: FromStateFeature.State, rhs: FromStateFeature.State) -> Bool {
    lhs.movies == rhs.movies &&
    lhs.titleSort == rhs.titleSort &&
    lhs.isSearchFieldPresented == rhs.isSearchFieldPresented &&
    lhs.searchString == rhs.searchString
  }
}
#else
extension FromStateFeature.State: Equatable {
  public static func == (lhs: FromStateFeature.State, rhs: FromStateFeature.State) -> Bool {
    lhs.movies == rhs.movies &&
    lhs.titleSort == rhs.titleSort &&
    lhs.isSearchFieldPresented == rhs.isSearchFieldPresented &&
    lhs.searchString == rhs.searchString
  }
}
#endif
