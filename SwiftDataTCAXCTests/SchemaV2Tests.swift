import ComposableArchitecture
import Foundation
import SwiftData
import XCTest

@testable import SwiftDataTCA

final class SchemaV2Tests: XCTestCase {
  typealias ActiveSchema = SchemaV2

  func testCreatingV2Database() async throws {
    withNewContext(ActiveSchema.self) { context in
      withDependencies {
        $0.uuid = .incrementing
      } operation: {
        ActiveSchema.makeMock(context: context, entry: ("The First Movie", ["Actor 1", "Actor 2", "Actor 3"]))
        ActiveSchema.makeMock(context: context, entry: ("A Second Movie", ["Actor 1", "Actor 4"]))
        ActiveSchema.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
        try! context.save()
      }

      var movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, uuidSort: .none, search: ""))

      XCTAssertEqual(movies.count, 3)
      XCTAssertEqual(movies[0].title, "A Second Movie")
      XCTAssertEqual(movies[1].title, "El Third Movie")
      XCTAssertEqual(movies[2].title, "The First Movie")

      XCTAssertEqual(movies[0].cast.count, 2)
      XCTAssertEqual(movies[0].cast[0], "Actor 1")
      XCTAssertEqual(movies[0].cast[1], "Actor 4")

      movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .reverse, uuidSort: .none, search: ""))

      XCTAssertEqual(movies.count, 3)
      XCTAssertEqual(movies[2].title, "A Second Movie")
      XCTAssertEqual(movies[1].title, "El Third Movie")
      XCTAssertEqual(movies[0].title, "The First Movie")

      movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, uuidSort: .forward, search: ""))

      XCTAssertEqual(movies.count, 3)
      XCTAssertEqual(movies[0].title, "The First Movie")
      XCTAssertEqual(movies[1].title, "A Second Movie")
      XCTAssertEqual(movies[2].title, "El Third Movie")

      movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, uuidSort: .reverse, search: ""))

      XCTAssertEqual(movies.count, 3)
      XCTAssertEqual(movies[2].title, "The First Movie")
      XCTAssertEqual(movies[1].title, "A Second Movie")
      XCTAssertEqual(movies[0].title, "El Third Movie")

      movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, uuidSort: .none, search: "th"))

      XCTAssertEqual(movies.count, 2)
      XCTAssertEqual(movies[0].title, "El Third Movie")
      XCTAssertEqual(movies[1].title, "The First Movie")
    }
  }
}
