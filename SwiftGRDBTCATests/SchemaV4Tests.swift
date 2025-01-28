#if canImport(Testing)

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import SwiftDataTCA

struct SchemaV4Tests {
  typealias ActiveSchema = SchemaV4

  /// NOTE to self: do not use `await container.mainContext` in tests
  /// NOTE to self: do not run Swift Data tests in parallel

  @Test func creatingV4Database() async throws {
    TestingSupport.withNewContext(ActiveSchema.self) { context in
      withDependencies {
        $0.uuid = .incrementing
      } operation: {
        @Dependency(\.uuid) var uuid
        ActiveSchema.makeMock(context: context, entry: ("A Second Movie", ["Actor 1", "Actor 2", "Actor 3"]))
        ActiveSchema.makeMock(context: context, entry: ("The First Movie", ["Actor 1", "Actor 4"]))
        ActiveSchema.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
      }
      try! context.save()
    }
  }

  @Test func fetchingV4() async throws {
    TestingSupport.withNewContext(ActiveSchema.self) { context in
      withDependencies {
        $0.uuid = .incrementing
      } operation: {
        ActiveSchema.makeMock(context: context, entry: ("A Second Movie", ["Actor 1", "Actor 2", "Actor 3"]))
        ActiveSchema.makeMock(context: context, entry: ("The First Movie", ["Actor 1", "Actor 4"]))
        ActiveSchema.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))

        try! context.save()

        var movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: ""))

        #expect(movies.count == 3)
        #expect(movies[0].title == "The First Movie")
        #expect(movies[1].title == "A Second Movie")
        #expect(movies[2].title == "El Third Movie")
        #expect(movies[0].actors.count == 2)
        #expect(movies[0].actors[0].movies.contains(movies[0]))
        #expect(movies[1].actors.count == 3)
        #expect(movies[2].actors.count == 1)

        movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .reverse, search: ""))

        #expect(movies.count == 3)
        #expect(movies[2].title == "The First Movie")
        #expect(movies[1].title == "A Second Movie")
        #expect(movies[0].title == "El Third Movie")

        movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: "th"))

        #expect(movies.count == 2)
        #expect(movies[0].title == "The First Movie")
        #expect(movies[1].title == "El Third Movie")

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
    }
  }

  @Test func migrationV3V4() async throws {
    typealias OldSchema = SchemaV3

    let url = FileManager.default.temporaryDirectory.appending(component: "Model4.sqlite")
    try? FileManager.default.removeItem(at: url)

    TestingSupport.withNewContext(OldSchema.self, storage: url) { context in
      withDependencies {
        $0.uuid = .incrementing
      } operation: {
        @Dependency(\.uuid) var uuid
        OldSchema.makeMock(context: context, entry: (title: "El Mariachi", cast: ["Foo Bar"]))
        OldSchema.makeMock(context: context, entry: (title: "The Way We Were", cast: ["Babs Strei", "Bob Woodward"]))
        OldSchema.makeMock(context: context, entry: (title: "Le Monde", cast: ["Zoe"]))
        OldSchema.makeMock(context: context, entry: (title: "Les Enfants", cast: ["Zoe"]))
        try! context.save()
        let moviesV3 = try! context.fetch(OldSchema.movieFetchDescriptor(titleSort: .forward, uuidSort: .none, search: ""))
        #expect(moviesV3[0].title == "Les Enfants")
        #expect(moviesV3[1].title == "El Mariachi")
        #expect(moviesV3[2].title == "Le Monde")
        #expect(moviesV3[3].title == "The Way We Were")
      }
    }

    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      // Migrate to V4
      TestingSupport.withNewContext(ActiveSchema.self, migrationPlan: MockMigrationPlan.self, storage: url) { context in
        @Dependency(\.uuid) var uuid
        let moviesV4 = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, search: ""))

        #expect(moviesV4.count == 4)
        #expect(moviesV4[0].title == "Les Enfants")
        #expect(moviesV4[0].actors.count == 1)
        #expect(moviesV4[0].actors[0].name == "Zoe")

        #expect(moviesV4[1].title == "El Mariachi")
        #expect(moviesV4[1].actors.count == 1)
        #expect(moviesV4[1].actors[0].name == "Foo Bar")

        #expect(moviesV4[2].title == "Le Monde")
        #expect(moviesV4[2].actors.count == 1)
        #expect(moviesV4[2].actors[0].name == "Zoe")

        #expect(moviesV4[3].title == "The Way We Were")
        #expect(moviesV4[3].actors.count == 2)
        #expect(moviesV4[3].actors[0].name == "Babs Strei" || moviesV4[3].actors[0].name == "Bob Woodward")

        let actors = try! context.fetch(FetchDescriptor<ActiveSchema._Actor>(sortBy: [.init(\.name, order: .forward)]))

        #expect(actors.count == 4)
        #expect(actors[0].name == "Babs Strei")
        #expect(actors[0].movies.count == 1)
        #expect(actors[3].name == "Zoe")
        #expect(actors[3].movies.count == 2)
        #expect(actors[3].movies[0].title == "Le Monde" || actors[3].movies[0].title == "Les Enfants")
        #expect(actors[3].movies.count == 2)
      }
    }
  }
}

private enum MockMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] { [ SchemaV4.self, ] }
  static var stages: [MigrationStage] { [ StageV4.stage ] }
}

#endif
