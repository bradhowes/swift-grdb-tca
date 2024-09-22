import ComposableArchitecture
import Foundation
import SwiftData
import XCTest

@testable import SwiftDataTCA

final class SchemaV4Tests: XCTestCase {
  typealias ActiveSchema = SchemaV4

  func testCreatingV4Database() async throws {
    withNewContext(ActiveSchema.self) { context in
      withDependencies {
        $0.uuid = .incrementing
      } operation: {
        ActiveSchema.makeMock(context: context, entry: ("A Second Movie", ["Actor 1", "Actor 4"]))
        ActiveSchema.makeMock(context: context, entry: ("The First Movie", ["Actor 1", "Actor 2", "Actor 3"]))
        ActiveSchema.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
        try! context.save()
      }

      var movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: ""))

      XCTAssertEqual(movies.count, 3)
      XCTAssertEqual(movies[0].title, "The First Movie")
      XCTAssertEqual(movies[1].title, "A Second Movie")
      XCTAssertEqual(movies[2].title, "El Third Movie")

      XCTAssertEqual(movies[0].actors.count, 3)
      XCTAssertEqual(movies[1].actors.count, 2)
      XCTAssertEqual(movies[2].actors.count, 1)
      XCTAssertEqual(movies[2].actors[0].name, "Actor 2")

      movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .reverse, search: ""))

      XCTAssertEqual(movies.count, 3)
      XCTAssertEqual(movies[2].title, "The First Movie")
      XCTAssertEqual(movies[1].title, "A Second Movie")
      XCTAssertEqual(movies[0].title, "El Third Movie")

      movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: "th"))

      XCTAssertEqual(movies.count, 2)
      XCTAssertEqual(movies[0].title, "The First Movie")
      XCTAssertEqual(movies[1].title, "El Third Movie")
    }
  }

  func testMigrationV3V4() async throws {
    typealias OldSchema = SchemaV3

    let url = FileManager.default.temporaryDirectory.appending(component: "Model4.sqlite")
    try? FileManager.default.removeItem(at: url)

    withNewContext(OldSchema.self, storage: url) { context in
      withDependencies {
        $0.uuid = .incrementing
      } operation: {
        OldSchema.makeMock(context: context, entry: (title: "El Mariachi", cast: ["Foo Bar"]))
        OldSchema.makeMock(context: context, entry: (title: "The Way We Were", cast: ["Babs Strei", "Bob Woodward"]))
        OldSchema.makeMock(context: context, entry: (title: "Le Monde", cast: ["Zoe"]))
        OldSchema.makeMock(context: context, entry: (title: "Les Enfants", cast: ["Zoe"]))
        try! context.save()
      }

      let movies = try! context.fetch(SchemaV3.movieFetchDescriptor(titleSort: .forward, uuidSort: .none, search: ""))
      XCTAssertEqual(movies[0].title, "Les Enfants")
      XCTAssertEqual(movies[1].title, "El Mariachi")
      XCTAssertEqual(movies[2].title, "Le Monde")
      XCTAssertEqual(movies[3].title, "The Way We Were")
    }

    // Migrate to V4
    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      withNewContext(ActiveSchema.self, migrationPlan: MockMigrationPlan.self, storage: url) { context in
        let movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: ""))

        XCTAssertEqual(movies.count, 4)
        XCTAssertEqual(movies[0].title, "Les Enfants")
        XCTAssertEqual(movies[0].actors.count, 1)
        XCTAssertEqual(movies[0].actors[0].name, "Zoe")

        XCTAssertEqual(movies[1].title, "El Mariachi")
        XCTAssertEqual(movies[1].actors.count, 1)
        XCTAssertEqual(movies[1].actors[0].name, "Foo Bar")

        XCTAssertEqual(movies[2].title, "Le Monde")
        XCTAssertEqual(movies[2].actors.count, 1)
        XCTAssertEqual(movies[2].actors[0].name, "Zoe")

        XCTAssertEqual(movies[3].title, "The Way We Were")
        XCTAssertEqual(movies[3].actors.count, 2)

        let actors = try! context.fetch(FetchDescriptor<ActiveSchema._Actor>(sortBy: [.init(\.name, order: .forward)]))

        XCTAssertEqual(actors.count, 4)
        XCTAssertEqual(actors[0].name, "Babs Strei")
        XCTAssertEqual(actors[0].movies.count, 1)
        XCTAssertEqual(actors[3].name, "Zoe")
        XCTAssertEqual(actors[3].movies.count, 2)
        XCTAssertEqual(actors[3].movies.count, 2)
      }
    }
  }
}

private enum MockMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] { [ SchemaV3.self, SchemaV4.self, ] }
  static var stages: [MigrationStage] { [ StageV4.stage ] }
}
