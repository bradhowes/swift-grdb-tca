#if canImport(Testing)

import ComposableArchitecture
import Dependencies
import Foundation
import SwiftData
import Testing

@testable import SwiftDataTCA

struct SchemaV6Tests {
  typealias ActiveSchema = SchemaV6

  /// NOTE to self: do not use `await container.mainContext` in tests
  /// NOTE to self: do not run Swift Data tests in parallel

  @Test("Creating DB")
  func creatingDatabase() async throws {
    TestingSupport.withNewContext(ActiveSchema.self) { context in
      ActiveSchema.makeMock(context: context, entry: ("A Second Movie", ["Actor 1", "Actor 4"]))
      ActiveSchema.makeMock(context: context, entry: ("The First Movie", ["Actor 1", "Actor 2", "Actor 3"]))
      ActiveSchema.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
      try! context.save()
        
      let movies = try! context.fetch(FetchDescriptor<ActiveSchema.MovieModel>(sortBy: [.init(\.sortableTitle, order: .forward)]))
        
      #expect(movies.count == 3)
      #expect(movies[0].title == "The First Movie")
      #expect(movies[1].title == "A Second Movie")
      #expect(movies[2].title == "El Third Movie")
      #expect(movies[0].actors.count == 3)
      #expect(movies[0].actors[0].movies.contains(movies[0]))
      #expect(movies[1].actors.count == 2)
      #expect(movies[2].actors.count == 1)
        
      let actors = try! context.fetch(FetchDescriptor<ActiveSchema.ActorModel>(sortBy: [.init(\.name, order: .forward)]))
        
      #expect(actors.count == 4)
      #expect(actors[0].name == "Actor 1")
      #expect(actors[1].name == "Actor 2")
      #expect(actors[2].name == "Actor 3")
      #expect(actors[3].name == "Actor 4")
      #expect(actors[0].movies.count == 2)
      #expect(actors[0].movies[0].actors.contains(actors[0]))
      #expect(actors[0].movies[1].actors.contains(actors[0]))
    }
  }

  @Test("Migrating from V5 to V6")
  func migrationV5V6() async throws {
    typealias OldSchema = SchemaV5

    let url = FileManager.default.temporaryDirectory.appending(component: "Model6.sqlite")
    try? FileManager.default.removeItem(at: url)

    TestingSupport.withNewContext(OldSchema.self, storage: url) { context in
      OldSchema.makeMock(context: context, entry: ("A Second Movie", ["Actor 1", "Actor 4"]))
      OldSchema.makeMock(context: context, entry: ("The First Movie", ["Actor 2", "Actor 1", "Actor 3"]))
      OldSchema.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
      try! context.save()

      let movies = try! context.fetch(OldSchema.movieFetchDescriptor(titleSort: .forward, search: ""))
      #expect(movies[0].title == "The First Movie")
      #expect(movies[1].title == "A Second Movie")
      #expect(movies[2].title == "El Third Movie")
    }

    // Migrate to V6
    TestingSupport.withNewContext(ActiveSchema.self, migrationPlan: MockMigrationPlan.self, storage: url) { context in
      let movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: ""))

      #expect(movies.count == 3)
      #expect(movies[0].title == "The First Movie")
      #expect(movies[0].actors.count == 3)

      #expect(movies[1].title == "A Second Movie")
      #expect(movies[1].actors.count == 2)
      #expect(movies[1].actors[0].name == "Actor 1" || movies[1].actors[0].name == "Actor 4")

      #expect(movies[2].title == "El Third Movie")
      #expect(movies[2].actors.count == 1)
      #expect(movies[2].actors[0].name == "Actor 2")
    }
  }

  @Test("Struct generation")
  func structGeneration() async throws {
    TestingSupport.withNewContext(ActiveSchema.self) { context in
      ActiveSchema.makeMock(context: context, entry: ("A Second Movie", ["Actor 4", "Actor 1"]))
      ActiveSchema.makeMock(context: context, entry: ("The First Movie", ["Actor 2", "Actor 1", "Actor 3"]))
      ActiveSchema.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
      try! context.save()
      
      let movies = try! context.fetch(FetchDescriptor<ActiveSchema.MovieModel>(sortBy: [.init(\.sortableTitle, order: .forward)]))
      let actors = try! context.fetch(FetchDescriptor<ActiveSchema.ActorModel>(sortBy: [.init(\.name, order: .forward)]))
      
      #expect(movies.count == 3)
      #expect(movies[0].title == "The First Movie")
      #expect(movies[0].actors.count == 3)
      
      let m0 = movies[0].valueType
      #expect(m0.name == "The First Movie")
      #expect(m0.modelId == movies[0].persistentModelID)
      var ma = m0.actors(ordering: .forward)
      #expect(ma.count == 3)
      #expect(ma[0].name == "Actor 1")
      #expect(ma[0].modelId == actors[0].persistentModelID)
      #expect(ma[1].name == "Actor 2")
      #expect(ma[1].modelId == actors[1].persistentModelID)
      #expect(ma[2].name == "Actor 3")
      #expect(ma[2].modelId == actors[2].persistentModelID)

      let m1 = movies[1].valueType
      #expect(m1.name == "A Second Movie")
      #expect(m1.modelId == movies[1].persistentModelID)
      ma = m1.actors(ordering: .forward)
      #expect(ma.count == 2)
      #expect(ma[0].name == "Actor 1")
      #expect(ma[1].name == "Actor 4")
      
      let m2 = movies[2].valueType
      #expect(m2.name == "El Third Movie")
      #expect(m2.modelId == movies[2].persistentModelID)
      ma = m2.actors(ordering: .forward)
      #expect(ma.count == 1)
      #expect(ma[0].name == "Actor 2")
      
      #expect(actors.count == 4)
      #expect(actors[0].name == "Actor 1")
      #expect(actors[0].movies.count == 2)
      
      let a0 = actors[0].valueType
      #expect(a0.name == "Actor 1")
      #expect(a0.modelId == actors[0].persistentModelID)
      let am = a0.movies(ordering: .forward)
      #expect(am.count == 2)
      #expect(am[0].name == "The First Movie")
      #expect(am[0].modelId == movies[0].persistentModelID)
      #expect(am[1].name == "A Second Movie")
      #expect(am[1].modelId == movies[1].persistentModelID)
    }
  }

  @Test("Deleting Movie removes it from Actor relationship")
  func deleting() async throws {
    TestingSupport.withNewContext(ActiveSchema.self) { context in
      @Dependency(\.database) var db
      ActiveSchema.makeMock(context: context, entry: ("A Second Movie", ["Actor 4", "Actor 1"]))
      ActiveSchema.makeMock(context: context, entry: ("The First Movie", ["Actor 2", "Actor 1", "Actor 3"]))
      ActiveSchema.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
      try! context.save()

      var movies = db.fetchMovies(ActiveSchema.movieFetchDescriptor())
      #expect(movies.count == 3)
      #expect(movies[0].title == "The First Movie")
      #expect(movies[0].actors.count == 3)

      var actors = movies[0].sortedActors(order: .forward)
      #expect(actors.count == 3)
      #expect(actors[1].name == "Actor 2")

      movies = actors[0].sortedMovies(order: .forward)
      #expect(movies[0].title == "The First Movie")

      // Delete "The First Movie"
      db.delete(movies[0])
      movies = db.fetchMovies(ActiveSchema.movieFetchDescriptor())

      #expect(movies.count == 2)
      #expect(movies[1].title == "El Third Movie")
      #expect(movies[1].actors.count == 1)

      // Confirm that Actor 2 no longer holds a relation to "The First Movie"
      actors = movies[1].sortedActors(order: .forward)
      #expect(actors.count == 1)
      movies = actors[0].sortedMovies(order: .forward)
      #expect(movies.count == 1)
    }
  }
}

private enum MockMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] { [ SchemaV6.self, ] }
  static var stages: [MigrationStage] { [ StageV6.stage ] }
}

#endif
