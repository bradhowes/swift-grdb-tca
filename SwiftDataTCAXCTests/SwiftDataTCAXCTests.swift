import ComposableArchitecture
import Foundation
import SwiftData
import XCTest

@testable import SwiftDataTCA

final class SwiftDataTCAXCTests: XCTestCase {

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  @MainActor
  func testFromStateAddButtonTapped() async throws {
    let store = TestStore(initialState: FromStateFeature.State()) {
      FromStateFeature()
    } withDependencies: {
      $0.uuid = .constant(UUID(0))
      $0.withRandomNumberGenerator = .init(LCRNG(seed: 0))
      $0.movieDatabase.add = {
        @Dependency(\.modelContextProvider.context) var modelContextProvider
        let context = modelContextProvider()
        SchemaV4.makeMock(context: context)
      }
      $0.movieDatabase.fetchMovies = { descriptor in
        @Dependency(\.modelContextProvider.context) var modelContextProvider
        let movieContext = modelContextProvider()
        return (try? movieContext.fetch(descriptor)) ?? []
      }
      $0.movieDatabase.save = {
        @Dependency(\.modelContextProvider.context) var modelContextProvider
        let movieContext = modelContextProvider()
        try? movieContext.save()
      }
    }

    store.exhaustivity = .off
    await store.send(.addButtonTapped)
    await store.receive(\._fetchMovies)

    XCTAssertEqual(1, store.state.movies.count)
    XCTAssertEqual("Avatar", store.state.movies[0].title)
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
    lhs.uuidSort == rhs.uuidSort &&
    lhs.isSearchFieldPresented == rhs.isSearchFieldPresented &&
    lhs.searchString == rhs.searchString
  }
}
#else
extension FromStateFeature.State: Equatable {
  public static func == (lhs: FromStateFeature.State, rhs: FromStateFeature.State) -> Bool {
    lhs.movies == rhs.movies &&
    lhs.titleSort == rhs.titleSort &&
    lhs.uuidSort == rhs.uuidSort &&
    lhs.isSearchFieldPresented == rhs.isSearchFieldPresented &&
    lhs.searchString == rhs.searchString
  }
}
#endif
