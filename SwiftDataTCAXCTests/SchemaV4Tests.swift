import ComposableArchitecture
import Foundation
import SwiftData
import XCTest

@testable import SwiftDataTCA

final class SchemaV4Tests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }

  func testCreatingV4Database() async throws {
    let schema = Schema(versionedSchema: SchemaV4.self)
    let config = ModelConfiguration("V4", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = ModelContext(container)

    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      SchemaV4.makeMock(context: context, entry: ("A Second Movie", ["Actor 1", "Actor 4"]))
      SchemaV4.makeMock(context: context, entry: ("The First Movie", ["Actor 1", "Actor 2", "Actor 3"]))
      SchemaV4.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
      try! context.save()
    }

    var movies = try! context.fetch(SchemaV4.movieFetchDescriptor(titleSort: .forward, search: ""))

    XCTAssertEqual(movies.count, 3)
    XCTAssertEqual(movies[0].title, "The First Movie")
    XCTAssertEqual(movies[1].title, "A Second Movie")
    XCTAssertEqual(movies[2].title, "El Third Movie")

    XCTAssertEqual(movies[0].actors.count, 3)
    XCTAssertEqual(movies[1].actors.count, 2)
    XCTAssertEqual(movies[2].actors.count, 1)
    XCTAssertEqual(movies[2].actors[0].name, "Actor 2")

    movies = try! context.fetch(SchemaV4.movieFetchDescriptor(titleSort: .reverse, search: ""))

    XCTAssertEqual(movies.count, 3)
    XCTAssertEqual(movies[2].title, "The First Movie")
    XCTAssertEqual(movies[1].title, "A Second Movie")
    XCTAssertEqual(movies[0].title, "El Third Movie")

    movies = try! context.fetch(SchemaV4.movieFetchDescriptor(titleSort: .forward, search: "th"))

    XCTAssertEqual(movies.count, 2)
    XCTAssertEqual(movies[0].title, "The First Movie")
    XCTAssertEqual(movies[1].title, "El Third Movie")
  }

  func testMigrationV3V4() async throws {
    let url = FileManager.default.temporaryDirectory.appending(component: "Model4.sqlite")
    try? FileManager.default.removeItem(at: url)

    let schemaV3 = Schema(versionedSchema: SchemaV3.self)
    let configV3 = ModelConfiguration(schema: schemaV3, url: url)
    let containerV3 = try! ModelContainer(for: schemaV3, migrationPlan: nil, configurations: configV3)
    let contextV3 = ModelContext(containerV3)

    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      SchemaV3.makeMock(context: contextV3, entry: (title: "El Mariachi", cast: ["Foo Bar"]))
      SchemaV3.makeMock(context: contextV3, entry: (title: "The Way We Were", cast: ["Babs Strei", "Bob Woodward"]))
      SchemaV3.makeMock(context: contextV3, entry: (title: "Le Monde", cast: ["Zoe"]))
      SchemaV3.makeMock(context: contextV3, entry: (title: "Les Enfants", cast: ["Zoe"]))
      try! contextV3.save()
    }

    let moviesV3 = try! contextV3.fetch(SchemaV3.movieFetchDescriptor(titleSort: .forward, uuidSort: .none, search: ""))
    XCTAssertEqual(moviesV3[0].title, "Les Enfants")
    XCTAssertEqual(moviesV3[1].title, "El Mariachi")
    XCTAssertEqual(moviesV3[2].title, "Le Monde")
    XCTAssertEqual(moviesV3[3].title, "The Way We Were")

    let schemaV4 = Schema(versionedSchema: SchemaV4.self)
    let configV4 = ModelConfiguration(schema: schemaV4, url: url)
    let containerV4: ModelContainer = withDependencies {
      $0.uuid = .incrementing
    } operation: {
      // Migrate to V4
      return try! ModelContainer(for: schemaV4, migrationPlan: MockMigrationPlan.self,
                                 configurations: configV4)
    }

    let contextV4 = ModelContext(containerV4)
    let moviesV4 = try! contextV4.fetch(SchemaV4.movieFetchDescriptor(titleSort: .forward, search: ""))

    XCTAssertEqual(moviesV4.count, moviesV3.count)
    XCTAssertEqual(moviesV4[0].title, "Les Enfants")
    XCTAssertEqual(moviesV4[0].actors.count, 1)
    XCTAssertEqual(moviesV4[0].actors[0].name, "Zoe")

    XCTAssertEqual(moviesV4[1].title, "El Mariachi")
    XCTAssertEqual(moviesV4[1].actors.count, 1)
    XCTAssertEqual(moviesV4[1].actors[0].name, "Foo Bar")

    XCTAssertEqual(moviesV4[2].title, "Le Monde")
    XCTAssertEqual(moviesV4[2].actors.count, 1)
    XCTAssertEqual(moviesV4[2].actors[0].name, "Zoe")

    XCTAssertEqual(moviesV4[3].title, "The Way We Were")
    XCTAssertEqual(moviesV4[3].actors.count, 2)

    let actors = try! contextV4.fetch(FetchDescriptor<SchemaV4._Actor>(sortBy: [.init(\.name, order: .forward)]))

    XCTAssertEqual(actors.count, 4)
    XCTAssertEqual(actors[0].name, "Babs Strei")
    XCTAssertEqual(actors[0].movies.count, 1)
    XCTAssertEqual(actors[3].name, "Zoe")
    XCTAssertEqual(actors[3].movies.count, 2)
    XCTAssertEqual(actors[3].movies.count, 2)
  }
}

private enum MockMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] { [ SchemaV4.self, ] }
  static var stages: [MigrationStage] { [ StageV4.stage ] }
}
