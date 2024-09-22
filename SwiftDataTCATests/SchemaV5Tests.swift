#if canImport(Testing)

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import SwiftDataTCA

struct SchemaV5Tests {
  typealias ActiveSchema = SchemaV5

  /// NOTE to self: do not use `await container.mainContext` in tests
  /// NOTE to self: do not run Swift Data tests in parallel

  @Test("Creating DB")
  func creatingDatabase() async throws {
    let context = TestingSupport.makeContext(ActiveSchema.self)
    defer { TestingSupport.cleanup(context) }

    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      ActiveSchema.makeMock(context: context, entry: ("A Second Movie", ["Actor 1", "Actor 4"]))
      ActiveSchema.makeMock(context: context, entry: ("The First Movie", ["Actor 1", "Actor 2", "Actor 3"]))
      ActiveSchema.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
      try! context.save()
    }

    let movies = try! context.fetch(FetchDescriptor<ActiveSchema._Movie>(sortBy: [.init(\.sortableTitle, order: .forward)]))

    #expect(movies.count == 3)
    #expect(movies[0].title == "The First Movie")
    #expect(movies[1].title == "A Second Movie")
    #expect(movies[2].title == "El Third Movie")
    #expect(movies[0].actors.count == 3)
    #expect(movies[0].actors[0].movies.contains(movies[0]))
    #expect(movies[1].actors.count == 2)
    #expect(movies[2].actors.count == 1)

    let actors = try! context.fetch(FetchDescriptor<ActiveSchema._Actor>(sortBy: [.init(\.name, order: .forward)]))

    #expect(actors.count == 4)
    #expect(actors[0].name == "Actor 1")
    #expect(actors[1].name == "Actor 2")
    #expect(actors[2].name == "Actor 3")
    #expect(actors[3].name == "Actor 4")
    #expect(actors[0].movies.count == 2)
    #expect(actors[0].movies[0].actors.contains(actors[0]))
    #expect(actors[0].movies[1].actors.contains(actors[0]))
  }

  @Test("Migrating from V4 to V5")
  func migrationV4V5() async throws {
    typealias OldSchema = SchemaV4

    let url = FileManager.default.temporaryDirectory.appending(component: "Model5.sqlite")
    try? FileManager.default.removeItem(at: url)
    let oldContext = TestingSupport.makeContext(OldSchema.self, storage: url)
    defer { TestingSupport.cleanup(oldContext) }

    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      OldSchema.makeMock(context: oldContext, entry: ("A Second Movie", ["Actor 1", "Actor 4"]))
      OldSchema.makeMock(context: oldContext, entry: ("The First Movie", ["Actor 1", "Actor 2", "Actor 3"]))
      OldSchema.makeMock(context: oldContext, entry: ("El Third Movie", ["Actor 2"]))
      try! oldContext.save()

      let oldMovies = try! oldContext.fetch(OldSchema.movieFetchDescriptor(titleSort: .forward, search: ""))
      #expect(oldMovies[0].title == "The First Movie")
      #expect(oldMovies[1].title == "A Second Movie")
      #expect(oldMovies[2].title == "El Third Movie")
    }

    // Migrate to V5
    let newContext = TestingSupport.makeContext(ActiveSchema.self, migrationPlan: MockMigrationPlan.self, storage: url)
    defer { TestingSupport.cleanup(newContext) }

    withDependencies {
      $0.modelContextProvider = newContext
    } operation: {
      let newMovies = try! newContext.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: ""))
      
      #expect(newMovies.count == 3)
      #expect(newMovies[0].title == "The First Movie")
      #expect(newMovies[0].actors.count == 3)
      
      #expect(newMovies[1].title == "A Second Movie")
      #expect(newMovies[1].actors.count == 2)
      #expect(newMovies[1].actors[0].name == "Actor 1" || newMovies[1].actors[0].name == "Actor 4")
      
      #expect(newMovies[2].title == "El Third Movie")
      #expect(newMovies[2].actors.count == 1)
      #expect(newMovies[2].actors[0].name == "Actor 2")
    }
  }
}

private enum MockMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] { [ SchemaV5.self, ] }
  static var stages: [MigrationStage] { [ StageV5.stage ] }
}

#endif
