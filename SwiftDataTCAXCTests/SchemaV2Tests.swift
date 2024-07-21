import ComposableArchitecture
import Foundation
import SwiftData
import XCTest

@testable import SwiftDataTCA

final class SchemaV2Tests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }

  func testCreatingV2Database() async throws {
    let schema = Schema(versionedSchema: SchemaV2.self)
    let config = ModelConfiguration("V2", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = ModelContext(container)

    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      SchemaV2.makeMock(context: context, entry: ("The First Movie", ["Actor 1", "Actor 2", "Actor 3"]))
      SchemaV2.makeMock(context: context, entry: ("A Second Movie", ["Actor 1", "Actor 4"]))
      SchemaV2.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
      try! context.save()
    }

    var movies = try! context.fetch(SchemaV2.movieFetchDescriptor(titleSort: .forward, uuidSort: .none,
                                                                  searchString: ""))

    XCTAssertEqual(movies.count, 3)
    XCTAssertEqual(movies[0].title, "A Second Movie")
    XCTAssertEqual(movies[1].title, "El Third Movie")
    XCTAssertEqual(movies[2].title, "The First Movie")

    XCTAssertEqual(movies[0].cast.count, 2)
    XCTAssertEqual(movies[0].cast[0], "Actor 1")
    XCTAssertEqual(movies[0].cast[1], "Actor 4")

    movies = try! context.fetch(SchemaV2.movieFetchDescriptor(titleSort: .reverse, uuidSort: .none,
                                                              searchString: ""))

    XCTAssertEqual(movies.count, 3)
    XCTAssertEqual(movies[2].title, "A Second Movie")
    XCTAssertEqual(movies[1].title, "El Third Movie")
    XCTAssertEqual(movies[0].title, "The First Movie")

    movies = try! context.fetch(SchemaV2.movieFetchDescriptor(titleSort: .none, uuidSort: .forward,
                                                              searchString: ""))

    XCTAssertEqual(movies.count, 3)
    XCTAssertEqual(movies[0].title, "The First Movie")
    XCTAssertEqual(movies[1].title, "A Second Movie")
    XCTAssertEqual(movies[2].title, "El Third Movie")

    movies = try! context.fetch(SchemaV2.movieFetchDescriptor(titleSort: .none, uuidSort: .reverse,
                                                              searchString: ""))

    XCTAssertEqual(movies.count, 3)
    XCTAssertEqual(movies[2].title, "The First Movie")
    XCTAssertEqual(movies[1].title, "A Second Movie")
    XCTAssertEqual(movies[0].title, "El Third Movie")

    movies = try! context.fetch(SchemaV2.movieFetchDescriptor(titleSort: .forward, uuidSort: .none,
                                                              searchString: "th"))

    XCTAssertEqual(movies.count, 2)
    XCTAssertEqual(movies[0].title, "El Third Movie")
    XCTAssertEqual(movies[1].title, "The First Movie")
  }
}

