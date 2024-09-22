import ComposableArchitecture
import Foundation
import SwiftData
import XCTest

@testable import SwiftDataTCA

final class SchemaV3Tests: XCTestCase {
  typealias ActiveSchema = SchemaV3

  func testCreatingV3Database() async throws {
    withNewContext(ActiveSchema.self) { context in
      withDependencies {
        $0.uuid = .incrementing
      } operation: {
        ActiveSchema.makeMock(context: context, entry: ("A Second Movie", ["Actor 1", "Actor 4"]))
        ActiveSchema.makeMock(context: context, entry: ("The First Movie", ["Actor 1", "Actor 2", "Actor 3"]))
        ActiveSchema.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
        try! context.save()
      }

      var movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, uuidSort: .none,
                                                                        search: ""))

      XCTAssertEqual(movies.count, 3)
      XCTAssertEqual(movies[0].title, "The First Movie")
      XCTAssertEqual(movies[1].title, "A Second Movie")
      XCTAssertEqual(movies[2].title, "El Third Movie")

      XCTAssertEqual(movies[0].cast.count, 3)
      XCTAssertEqual(movies[0].cast[0], "Actor 1")
      XCTAssertEqual(movies[0].cast[1], "Actor 2")
      XCTAssertEqual(movies[0].cast[2], "Actor 3")

      movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .reverse, uuidSort: .none,
                                                                    search: ""))

      XCTAssertEqual(movies.count, 3)
      XCTAssertEqual(movies[2].title, "The First Movie")
      XCTAssertEqual(movies[1].title, "A Second Movie")
      XCTAssertEqual(movies[0].title, "El Third Movie")

      movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, uuidSort: .forward,
                                                                    search: ""))

      XCTAssertEqual(movies.count, 3)
      XCTAssertEqual(movies[0].title, "A Second Movie")
      XCTAssertEqual(movies[1].title, "The First Movie")
      XCTAssertEqual(movies[2].title, "El Third Movie")

      movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, uuidSort: .reverse,
                                                                    search: ""))

      XCTAssertEqual(movies.count, 3)
      XCTAssertEqual(movies[2].title, "A Second Movie")
      XCTAssertEqual(movies[1].title, "The First Movie")
      XCTAssertEqual(movies[0].title, "El Third Movie")

      movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, uuidSort: .none,
                                                                    search: "th"))

      XCTAssertEqual(movies.count, 2)
      XCTAssertEqual(movies[0].title, "The First Movie")
      XCTAssertEqual(movies[1].title, "El Third Movie")
    }
  }

  func testMigrationV2V3() async throws {
    typealias OldSchema = SchemaV2

    let url = FileManager.default.temporaryDirectory.appending(component: "Model3.sqlite")
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

      let movies = try! context.fetch(OldSchema.movieFetchDescriptor(titleSort: .forward, uuidSort: .none, search: ""))
      XCTAssertEqual(movies[0].title, "El Mariachi")
      XCTAssertEqual(movies[1].title, "Le Monde")
      XCTAssertEqual(movies[2].title, "Les Enfants")
      XCTAssertEqual(movies[3].title, "The Way We Were")
    }

    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      withNewContext(ActiveSchema.self, migrationPlan: MockMigrationPlan.self, storage: url) { context in
        let movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, uuidSort: .none, search: ""))

        XCTAssertEqual(movies.count, 4)
        XCTAssertEqual(movies[0].title, "Les Enfants")
        XCTAssertEqual(movies[0].cast.count, 1)
        XCTAssertEqual(movies[0].cast[0], "Zoe")

        XCTAssertEqual(movies[1].title, "El Mariachi")
        XCTAssertEqual(movies[1].cast.count, 1)
        XCTAssertEqual(movies[1].cast[0], "Foo Bar")

        XCTAssertEqual(movies[2].title, "Le Monde")
        XCTAssertEqual(movies[2].cast.count, 1)
        XCTAssertEqual(movies[2].cast[0], "Zoe")

        XCTAssertEqual(movies[3].title, "The Way We Were")
        XCTAssertEqual(movies[3].cast.count, 2)
      }
    }
  }
}

private enum MockMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] { [ SchemaV3.self, ] }
  static var stages: [MigrationStage] { [ StageV3.stage ] }
}
