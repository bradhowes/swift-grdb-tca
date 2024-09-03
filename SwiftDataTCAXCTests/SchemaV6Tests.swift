import ComposableArchitecture
import Foundation
import SwiftData
import XCTest

@testable import SwiftDataTCA

final class SchemaV6Tests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }

  func testCreatingV5Database() async throws {
    let schema = Schema(versionedSchema: SchemaV6.self)
    let config = ModelConfiguration("V6", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = ModelContext(container)

    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      SchemaV6.makeMock(context: context, entry: ("A Second Movie", ["Actor 1", "Actor 4"]))
      SchemaV6.makeMock(context: context, entry: ("The First Movie", ["Actor 1", "Actor 2", "Actor 3"]))
      SchemaV6.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
      try! context.save()
    }

    var movies = try! context.fetch(SchemaV6.movieFetchDescriptor(titleSort: .forward, search: ""))

    XCTAssertEqual(movies.count, 3)
    XCTAssertEqual(movies[0].title, "The First Movie")
    XCTAssertEqual(movies[1].title, "A Second Movie")
    XCTAssertEqual(movies[2].title, "El Third Movie")

    XCTAssertEqual(movies[0].actors.count, 3)
    XCTAssertEqual(movies[1].actors.count, 2)
    XCTAssertEqual(movies[2].actors.count, 1)
    XCTAssertEqual(movies[2].actors[0].name, "Actor 2")

    movies = try! context.fetch(SchemaV6.movieFetchDescriptor(titleSort: .reverse, search: ""))

    XCTAssertEqual(movies.count, 3)
    XCTAssertEqual(movies[2].title, "The First Movie")
    XCTAssertEqual(movies[1].title, "A Second Movie")
    XCTAssertEqual(movies[0].title, "El Third Movie")

    movies = try! context.fetch(SchemaV6.movieFetchDescriptor(titleSort: .forward, search: "th"))

    XCTAssertEqual(movies.count, 2)
    XCTAssertEqual(movies[0].title, "The First Movie")
    XCTAssertEqual(movies[1].title, "El Third Movie")
  }

  func testMigrationV5V6() async throws {
    typealias OldSchema = SchemaV5
    typealias NewSchema = SchemaV6

    let url = FileManager.default.temporaryDirectory.appending(component: "Model6.sqlite")
    try? FileManager.default.removeItem(at: url)

    let oldSchema = Schema(versionedSchema: OldSchema.self)
    let oldConfig = ModelConfiguration(schema: oldSchema, url: url)
    let oldContainer = try! ModelContainer(for: oldSchema, migrationPlan: nil, configurations: oldConfig)
    let oldContext = ModelContext(oldContainer)

    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      OldSchema.makeMock(context: oldContext, entry: ("A Second Movie", ["Actor 1", "Actor 4"]))
      OldSchema.makeMock(context: oldContext, entry: ("The First Movie", ["Actor 1", "Actor 2", "Actor 3"]))
      OldSchema.makeMock(context: oldContext, entry: ("El Third Movie", ["Actor 2"]))
      try! oldContext.save()
    }

    let oldMovies = try! oldContext.fetch(OldSchema.movieFetchDescriptor(titleSort: .forward, search: ""))
    XCTAssertEqual(oldMovies.count, 3)
    XCTAssertEqual(oldMovies[0].title, "The First Movie")
    XCTAssertEqual(oldMovies[1].title, "A Second Movie")
    XCTAssertEqual(oldMovies[2].title, "El Third Movie")

    // Migrate to V6
    let newSchema = Schema(versionedSchema: NewSchema.self)
    let newConfig = ModelConfiguration(schema: newSchema, url: url)
    let newContainer = try! ModelContainer(for: newSchema, migrationPlan: MockMigrationPlan.self,
                                          configurations: newConfig)

    let newContext = ModelContext(newContainer)
    let newMovies = try! newContext.fetch(NewSchema.movieFetchDescriptor(titleSort: .forward, search: ""))

    XCTAssertEqual(newMovies.count, oldMovies.count)
    XCTAssertEqual(newMovies[0].title, "The First Movie")
    XCTAssertEqual(newMovies[0].actors.count, 3)

    XCTAssertEqual(newMovies[1].title, "A Second Movie")
    XCTAssertEqual(newMovies[1].actors.count, 2)

    XCTAssertEqual(newMovies[2].title, "El Third Movie")
    XCTAssertEqual(newMovies[2].actors.count, 1)
    XCTAssertEqual(newMovies[2].actors[0].name, "Actor 2")
  }
}

private enum MockMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] { [ SchemaV6.self, ] }
  static var stages: [MigrationStage] { [ StageV6.stage ] }
}
