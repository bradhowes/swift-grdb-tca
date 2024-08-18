import ComposableArchitecture
import Dependencies
import Foundation
import SnapshotTesting
import SwiftData
import XCTest

@testable import SwiftDataTCA

final class FromQueryFeatureTests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
    @Dependency(\.modelContextProvider.container) var container
    container.deleteAllData()
  }

  @MainActor
  func testAddButtonTapped() async throws {
    let store = TestStore(initialState: FromQueryFeature.State()) {
      FromQueryFeature()
    } withDependencies: {
      $0.withRandomNumberGenerator = .init(LCRNG(seed: 0))
    }

    store.exhaustivity = .off
    await store.send(.addButtonTapped)

    @Dependency(\.modelContextProvider.context) var context
    let movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, searchString: ""))
    XCTAssertEqual(1, movies.count)
    XCTAssertEqual("The Score", movies[0].title)
  }

  @MainActor
  func testDeleteSwiped() async throws {
    let store = TestStore(initialState: FromQueryFeature.State()) {
      FromQueryFeature()
    } withDependencies: {
      $0.withRandomNumberGenerator = .init(LCRNG(seed: 0))
    }

    @Dependency(\.modelContextProvider.context) var context
    var movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, searchString: ""))
    XCTAssertTrue(movies.isEmpty)

    await store.send(.addButtonTapped)

    movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, searchString: ""))
    XCTAssertFalse(movies.isEmpty)
    let movie = movies[0].valueType
    await store.send(.deleteSwiped(movie))

    movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, searchString: ""))
    XCTAssertTrue(movies.isEmpty)
  }

  @MainActor
  func testFavoriteSwiped() async throws {
    let store = TestStore(initialState: FromQueryFeature.State()) {
      FromQueryFeature()
    } withDependencies: {
      $0.withRandomNumberGenerator = .init(LCRNG(seed: 0))
    }

    @Dependency(\.modelContextProvider.context) var context
    var movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, searchString: ""))
    XCTAssertTrue(movies.isEmpty)

    await store.send(.addButtonTapped)

    movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, searchString: ""))
    XCTAssertFalse(movies[0].favorite)
    let movie = movies[0].valueType
    await store.send(.favoriteSwiped(movie))

    XCTAssertTrue(movies[0].favorite)
  }

  @MainActor
  func testPreviewRender() throws {
    let view = FromQueryView.preview
    try assertSnapshot(matching: view)
  }

  @MainActor
  func testRootContentViewRender() throws {
    let view = RootContentView()
    try assertSnapshot(matching: view)
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
extension FromQueryFeature.State: @retroactive Equatable {
  public static func == (lhs: FromQueryFeature.State, rhs: FromQueryFeature.State) -> Bool {
    lhs.titleSort == rhs.titleSort &&
    lhs.isSearchFieldPresented == rhs.isSearchFieldPresented &&
    lhs.searchString == rhs.searchString
  }
}
#else
extension FromQueryFeature.State: Equatable {
  public static func == (lhs: FromQueryFeature.State, rhs: FromQueryFeature.State) -> Bool {
    lhs.titleSort == rhs.titleSort &&
    lhs.isSearchFieldPresented == rhs.isSearchFieldPresented &&
    lhs.searchString == rhs.searchString
  }
}
#endif
