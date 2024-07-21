import ComposableArchitecture
import Foundation
import SwiftData
import XCTest

@testable import SwiftDataTCA

final class SchemaV5Tests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }

  func testCreatingV5Database() async throws {
    let schema = Schema(versionedSchema: SchemaV5.self)
    let config = ModelConfiguration("V5", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = ModelContext(container)

    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      SchemaV5.makeMock(context: context, entry: ("A Second Movie", ["Actor 1", "Actor 4"]))
      SchemaV5.makeMock(context: context, entry: ("The First Movie", ["Actor 1", "Actor 2", "Actor 3"]))
      SchemaV5.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
      try! context.save()
    }

    var movies = try! context.fetch(SchemaV5.movieFetchDescriptor(titleSort: .forward, searchString: ""))

    XCTAssertEqual(movies.count, 3)
    XCTAssertEqual(movies[0].title, "The First Movie")
    XCTAssertEqual(movies[1].title, "A Second Movie")
    XCTAssertEqual(movies[2].title, "El Third Movie")

    XCTAssertEqual(movies[0].actors.count, 3)
    XCTAssertEqual(movies[1].actors.count, 2)
    XCTAssertEqual(movies[2].actors.count, 1)
    XCTAssertEqual(movies[2].actors[0].name, "Actor 2")

    movies = try! context.fetch(SchemaV5.movieFetchDescriptor(titleSort: .reverse, searchString: ""))

    XCTAssertEqual(movies.count, 3)
    XCTAssertEqual(movies[2].title, "The First Movie")
    XCTAssertEqual(movies[1].title, "A Second Movie")
    XCTAssertEqual(movies[0].title, "El Third Movie")

    movies = try! context.fetch(SchemaV5.movieFetchDescriptor(titleSort: .forward, searchString: "th"))

    XCTAssertEqual(movies.count, 2)
    XCTAssertEqual(movies[0].title, "The First Movie")
    XCTAssertEqual(movies[1].title, "El Third Movie")
  }

  func testMigrationV4V5() async throws {
    let url = FileManager.default.temporaryDirectory.appending(component: "Model5.sqlite")
    try? FileManager.default.removeItem(at: url)

    let schemaV4 = Schema(versionedSchema: SchemaV4.self)
    let configV4 = ModelConfiguration(schema: schemaV4, url: url)
    let containerV4 = try! ModelContainer(for: schemaV4, migrationPlan: nil, configurations: configV4)
    let contextV4 = ModelContext(containerV4)

    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      SchemaV4.makeMock(context: contextV4, entry: ("A Second Movie", ["Actor 1", "Actor 4"]))
      SchemaV4.makeMock(context: contextV4, entry: ("The First Movie", ["Actor 1", "Actor 2", "Actor 3"]))
      SchemaV4.makeMock(context: contextV4, entry: ("El Third Movie", ["Actor 2"]))
      try! contextV4.save()
    }

    let moviesV4 = try! contextV4.fetch(SchemaV4.movieFetchDescriptor(titleSort: .forward, searchString: ""))
    XCTAssertEqual(moviesV4.count, 3)
    XCTAssertEqual(moviesV4[0].title, "The First Movie")
    XCTAssertEqual(moviesV4[1].title, "A Second Movie")
    XCTAssertEqual(moviesV4[2].title, "El Third Movie")

    // Migrate to V5
    let schemaV5 = Schema(versionedSchema: SchemaV5.self)
    let configV5 = ModelConfiguration(schema: schemaV5, url: url)
    let containerV5 = try! ModelContainer(for: schemaV5, migrationPlan: MigrationPlan.self,
                                          configurations: configV5)

    let contextV5 = ModelContext(containerV5)
    let moviesV5 = try! contextV5.fetch(SchemaV5.movieFetchDescriptor(titleSort: .forward, searchString: ""))

    XCTAssertEqual(moviesV5.count, moviesV4.count)
    XCTAssertEqual(moviesV5[0].title, "The First Movie")
    XCTAssertEqual(moviesV5[0].actors.count, 3)

    XCTAssertEqual(moviesV5[1].title, "A Second Movie")
    XCTAssertEqual(moviesV5[1].actors.count, 2)

    XCTAssertEqual(moviesV5[2].title, "El Third Movie")
    XCTAssertEqual(moviesV5[2].actors.count, 1)
    XCTAssertEqual(moviesV5[2].actors[0].name, "Actor 2")
  }
}
