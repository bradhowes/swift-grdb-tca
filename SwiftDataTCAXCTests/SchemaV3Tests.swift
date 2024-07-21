import ComposableArchitecture
import Foundation
import SwiftData
import XCTest

@testable import SwiftDataTCA

final class SchemaV3Tests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }

  func testCreatingV3Database() async throws {
    let schema = Schema(versionedSchema: SchemaV3.self)
    let config = ModelConfiguration("V3", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = ModelContext(container)

    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      SchemaV3.makeMock(context: context, entry: ("A Second Movie", ["Actor 1", "Actor 4"]))
      SchemaV3.makeMock(context: context, entry: ("The First Movie", ["Actor 1", "Actor 2", "Actor 3"]))
      SchemaV3.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
      try! context.save()
    }

    var movies = try! context.fetch(SchemaV3.movieFetchDescriptor(titleSort: .forward, uuidSort: .none,
                                                                  searchString: ""))

    XCTAssertEqual(movies.count, 3)
    XCTAssertEqual(movies[0].title, "The First Movie")
    XCTAssertEqual(movies[1].title, "A Second Movie")
    XCTAssertEqual(movies[2].title, "El Third Movie")

    XCTAssertEqual(movies[0].cast.count, 3)
    XCTAssertEqual(movies[0].cast[0], "Actor 1")
    XCTAssertEqual(movies[0].cast[1], "Actor 2")
    XCTAssertEqual(movies[0].cast[2], "Actor 3")

    movies = try! context.fetch(SchemaV3.movieFetchDescriptor(titleSort: .reverse, uuidSort: .none,
                                                              searchString: ""))

    XCTAssertEqual(movies.count, 3)
    XCTAssertEqual(movies[2].title, "The First Movie")
    XCTAssertEqual(movies[1].title, "A Second Movie")
    XCTAssertEqual(movies[0].title, "El Third Movie")

    movies = try! context.fetch(SchemaV3.movieFetchDescriptor(titleSort: .none, uuidSort: .forward,
                                                              searchString: ""))

    XCTAssertEqual(movies.count, 3)
    XCTAssertEqual(movies[0].title, "A Second Movie")
    XCTAssertEqual(movies[1].title, "The First Movie")
    XCTAssertEqual(movies[2].title, "El Third Movie")

    movies = try! context.fetch(SchemaV3.movieFetchDescriptor(titleSort: .none, uuidSort: .reverse,
                                                              searchString: ""))

    XCTAssertEqual(movies.count, 3)
    XCTAssertEqual(movies[2].title, "A Second Movie")
    XCTAssertEqual(movies[1].title, "The First Movie")
    XCTAssertEqual(movies[0].title, "El Third Movie")

    movies = try! context.fetch(SchemaV3.movieFetchDescriptor(titleSort: .forward, uuidSort: .none,
                                                              searchString: "th"))

    XCTAssertEqual(movies.count, 2)
    XCTAssertEqual(movies[0].title, "The First Movie")
    XCTAssertEqual(movies[1].title, "El Third Movie")
  }

  func testMigrationV2V3() async throws {
    let url = FileManager.default.temporaryDirectory.appending(component: "Model3.sqlite")
    try? FileManager.default.removeItem(at: url)

    let schemaV2 = Schema(versionedSchema: SchemaV2.self)
    let configV2 = ModelConfiguration(schema: schemaV2, url: url)
    let containerV2 = try! ModelContainer(for: schemaV2, migrationPlan: nil, configurations: configV2)
    let contextV2 = ModelContext(containerV2)

    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      SchemaV2.makeMock(context: contextV2, entry: (title: "El Mariachi", cast: ["Foo Bar"]))
      SchemaV2.makeMock(context: contextV2, entry: (title: "The Way We Were", cast: ["Babs Strei", "Bob Woodward"]))
      SchemaV2.makeMock(context: contextV2, entry: (title: "Le Monde", cast: ["Zoe"]))
      SchemaV2.makeMock(context: contextV2, entry: (title: "Les Enfants", cast: ["Zoe"]))
      try! contextV2.save()
    }

    let moviesV2 = try! contextV2.fetch(SchemaV2.movieFetchDescriptor(titleSort: .forward, uuidSort: .none, searchString: ""))
    XCTAssertEqual(moviesV2[0].title, "El Mariachi")
    XCTAssertEqual(moviesV2[1].title, "Le Monde")
    XCTAssertEqual(moviesV2[2].title, "Les Enfants")
    XCTAssertEqual(moviesV2[3].title, "The Way We Were")

    let schemaV3 = Schema(versionedSchema: SchemaV3.self)
    let configV3 = ModelConfiguration(schema: schemaV3, url: url)
    let containerV3: ModelContainer = withDependencies {
      $0.uuid = .incrementing
    } operation: {
      // Migrate to V3
      return try! ModelContainer(for: schemaV3, migrationPlan: MockMigrationPlanV3.self,
                                 configurations: configV3)
    }

    let contextV3 = ModelContext(containerV3)
    let moviesV3 = try! contextV3.fetch(SchemaV3.movieFetchDescriptor(titleSort: .forward, uuidSort: .none, searchString: ""))

    XCTAssertEqual(moviesV3.count, moviesV3.count)
    XCTAssertEqual(moviesV3[0].title, "Les Enfants")
    XCTAssertEqual(moviesV3[0].cast.count, 1)
    XCTAssertEqual(moviesV3[0].cast[0], "Zoe")

    XCTAssertEqual(moviesV3[1].title, "El Mariachi")
    XCTAssertEqual(moviesV3[1].cast.count, 1)
    XCTAssertEqual(moviesV3[1].cast[0], "Foo Bar")

    XCTAssertEqual(moviesV3[2].title, "Le Monde")
    XCTAssertEqual(moviesV3[2].cast.count, 1)
    XCTAssertEqual(moviesV3[2].cast[0], "Zoe")

    XCTAssertEqual(moviesV3[3].title, "The Way We Were")
    XCTAssertEqual(moviesV3[3].cast.count, 2)
  }
}

private enum MockMigrationPlanV3: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] {
    [
      SchemaV3.self,
    ]
  }

  static var stages: [MigrationStage] {
    [
      StageV3.stage
    ]
  }
}
