import ComposableArchitecture
import Foundation
import SwiftData
import XCTest

@testable import SwiftDataTCA

final class SchemaV5Tests: XCTestCase {
  typealias ActiveSchema = SchemaV5

  func testCreatingV5Database() async throws {
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

  func testMigrationV4V5() async throws {
    typealias OldSchema = SchemaV4

    let url = FileManager.default.temporaryDirectory.appending(component: "Model5.sqlite")
    try? FileManager.default.removeItem(at: url)

    withNewContext(OldSchema.self, storage: url) { context in
      withDependencies {
        $0.uuid = .incrementing
      } operation: {
        OldSchema.makeMock(context: context, entry: ("A Second Movie", ["Actor 1", "Actor 4"]))
        OldSchema.makeMock(context: context, entry: ("The First Movie", ["Actor 1", "Actor 2", "Actor 3"]))
        OldSchema.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
        try! context.save()
      }

      let movies = try! context.fetch(OldSchema.movieFetchDescriptor(titleSort: .forward, search: ""))
      XCTAssertEqual(movies.count, 3)
      XCTAssertEqual(movies[0].title, "The First Movie")
      XCTAssertEqual(movies[1].title, "A Second Movie")
      XCTAssertEqual(movies[2].title, "El Third Movie")
    }

    // Migrate to V5
    withNewContext(ActiveSchema.self, migrationPlan: MockMigrationPlan.self, storage: url) { context in
      let movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: ""))
      XCTAssertEqual(movies.count, 3)
      XCTAssertEqual(movies[0].title, "The First Movie")
      XCTAssertEqual(movies[0].actors.count, 3)

      XCTAssertEqual(movies[1].title, "A Second Movie")
      XCTAssertEqual(movies[1].actors.count, 2)

      XCTAssertEqual(movies[2].title, "El Third Movie")
      XCTAssertEqual(movies[2].actors.count, 1)
      XCTAssertEqual(movies[2].actors[0].name, "Actor 2")
    }
  }
}

private enum MockMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] { [ SchemaV5.self, ] }
  static var stages: [MigrationStage] { [ StageV5.stage ] }
}
