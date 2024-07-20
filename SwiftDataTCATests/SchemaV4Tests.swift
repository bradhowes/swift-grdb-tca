#if canImport(Testing)

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import SwiftDataTCA


struct SchemaV4Tests {

  /// NOTE to self: do not use `await container.mainContext` in tests
  /// NOTE to self: do not run Swift Data tests in parallel

  @Test func creatingV4Database() async throws {
    let schema = Schema(versionedSchema: SchemaV4.self)
    let config = ModelConfiguration("V4", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = ModelContext(container)

    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      @Dependency(\.uuid) var uuid
      SchemaV4.makeMock(context: context, entry: ("A Second Movie", ["Actor 1", "Actor 2", "Actor 3"]))
      SchemaV4.makeMock(context: context, entry: ("The First Movie", ["Actor 1", "Actor 4"]))
      SchemaV4.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
    }
    try! context.save()
  }

  @Test func fetchingV4() async throws {
    let schema = Schema(versionedSchema: SchemaV4.self)
    print(schema.entitiesByName)
    let config = ModelConfiguration("fetchingV4", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = ModelContext(container)

    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      @Dependency(\.uuid) var uuid
      SchemaV4.makeMock(context: context, entry: ("A Second Movie", ["Actor 1", "Actor 2", "Actor 3"]))
      SchemaV4.makeMock(context: context, entry: ("The First Movie", ["Actor 1", "Actor 4"]))
      SchemaV4.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
    }
    try! context.save()

    var movies = try! context.fetch(SchemaV4.movieFetchDescriptor(titleSort: .forward, searchString: ""))

    #expect(movies.count == 3)
    #expect(movies[0].title == "The First Movie")
    #expect(movies[1].title == "A Second Movie")
    #expect(movies[2].title == "El Third Movie")
    #expect(movies[0].actors.count == 2)
    #expect(movies[0].actors[0].movies.contains(movies[0]))
    #expect(movies[1].actors.count == 3)
    #expect(movies[2].actors.count == 1)

    movies = try! context.fetch(SchemaV4.movieFetchDescriptor(titleSort: .reverse, searchString: ""))

    #expect(movies.count == 3)
    #expect(movies[2].title == "The First Movie")
    #expect(movies[1].title == "A Second Movie")
    #expect(movies[0].title == "El Third Movie")

    movies = try! context.fetch(SchemaV4.movieFetchDescriptor(titleSort: .forward, searchString: "th"))

    #expect(movies.count == 2)
    #expect(movies[0].title == "The First Movie")
    #expect(movies[1].title == "El Third Movie")

    let actors = try! context.fetch(FetchDescriptor<SchemaV4._Actor>(sortBy: [.init(\.name, order: .forward)]))

    #expect(actors.count == 4)
    #expect(actors[0].name == "Actor 1")
    #expect(actors[1].name == "Actor 2")
    #expect(actors[2].name == "Actor 3")
    #expect(actors[3].name == "Actor 4")
    #expect(actors[0].movies.count == 2)
    #expect(actors[0].movies[0].actors.contains(actors[0]))
    #expect(actors[0].movies[1].actors.contains(actors[0]))
  }

  @Test func migrationV3V4() async throws {
    let url = FileManager.default.temporaryDirectory.appending(component: "Model4.sqlite")
    try? FileManager.default.removeItem(at: url)

    let schemaV3 = Schema(versionedSchema: SchemaV3.self)
    let configV3 = ModelConfiguration(schema: schemaV3, url: url)
    let containerV3 = try! ModelContainer(for: schemaV3, migrationPlan: nil, configurations: configV3)

    @Dependency(\.uuid) var uuid
    let contextV3 = ModelContext(containerV3)
    SchemaV3.makeMock(context: contextV3, entry: (title: "El Mariachi", cast: ["Foo Bar"]))
    SchemaV3.makeMock(context: contextV3, entry: (title: "The Way We Were", cast: ["Babs Strei", "Bob Woodward"]))
    SchemaV3.makeMock(context: contextV3, entry: (title: "Le Monde", cast: ["Zoe"]))
    SchemaV3.makeMock(context: contextV3, entry: (title: "Les Enfants", cast: ["Zoe"]))
    try! contextV3.save()
    let moviesV3 = try! contextV3.fetch(SchemaV3.movieFetchDescriptor(titleSort: .forward, uuidSort: .none, searchString: ""))
    #expect(moviesV3[0].title == "Les Enfants")
    #expect(moviesV3[1].title == "El Mariachi")
    #expect(moviesV3[2].title == "Le Monde")
    #expect(moviesV3[3].title == "The Way We Were")

    // Migrate to V4
    let schemaV4 = Schema(versionedSchema: SchemaV4.self)
    let configV4 = ModelConfiguration(schema: schemaV4, url: url)
    let containerV4 = try! ModelContainer(for: schemaV4, migrationPlan: MockMigrationPlanV4.self,
                                          configurations: configV4)

    let contextV4 = ModelContext(containerV4)
    let moviesV4 = try! contextV4.fetch(SchemaV4.movieFetchDescriptor(titleSort: .forward, searchString: ""))

    #expect(moviesV4.count == moviesV3.count)
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

    let actors = try! contextV4.fetch(FetchDescriptor<SchemaV4._Actor>(sortBy: [.init(\.name, order: .forward)]))

    #expect(actors.count == 4)
    #expect(actors[0].name == "Babs Strei")
    #expect(actors[0].movies.count == 1)
    #expect(actors[3].name == "Zoe")
    #expect(actors[3].movies.count == 2)
    #expect(actors[3].movies[0].title == "Le Monde" || actors[3].movies[0].title == "Les Enfants")
    #expect(actors[3].movies.count == 2)
  }
}

enum MockMigrationPlanV4: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] {
    [
      SchemaV4.self,
    ]
  }

  static var stages: [MigrationStage] {
    [
      StageV4.stage
    ]
  }
}

private struct LCRNG: RandomNumberGenerator {
  var seed: UInt64
  mutating func next() -> UInt64 {
    self.seed = 2_862_933_555_777_941_757 &* self.seed &+ 3_037_000_493
    return self.seed
  }
}

#endif
