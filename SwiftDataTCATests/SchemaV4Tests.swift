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

    @Dependency(\.uuid) var uuid
    let m1 = SchemaV4._Movie(id: uuid(), title: "The First Movie")
    context.insert(m1)
    let m2 = SchemaV4._Movie(id: uuid(), title: "A Second Movie")
    context.insert(m2)
    let m3 = SchemaV4._Movie(id: uuid(), title: "El Third Movie")
    context.insert(m3)
    let a1 = SchemaV4._Actor(id: uuid(), name: "Actor 1")
    context.insert(a1)
    let a2 = SchemaV4._Actor(id: uuid(), name: "Actor 2")
    context.insert(a2)
    let a3 = SchemaV4._Actor(id: uuid(), name: "Actor 3")
    context.insert(a3)
    let a4 = SchemaV4._Actor(id: uuid(), name: "Actor 4")
    context.insert(a4)

    try! context.save()

    m1.addActor(a1)
    m1.addActor(a2)
    m1.addActor(a3)

    m2.addActor(a1)
    m2.addActor(a4)

    m3.addActor(a2)

    try! context.save()

    let movies = try! context.fetch(FetchDescriptor<SchemaV4._Movie>(sortBy: [.init(\.sortableTitle, order: .forward)]))

    #expect(movies.count == 3)
    #expect(movies[0].title == "The First Movie")
    #expect(movies[1].title == "A Second Movie")
    #expect(movies[2].title == "El Third Movie")
    #expect(movies[0].actors.count == 3)
    #expect(movies[0].actors[0].movies.contains(movies[0]))
    #expect(movies[1].actors.count == 2)
    #expect(movies[2].actors.count == 1)

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
    contextV3.insert(SchemaV3._Movie(id: uuid(), title: "El Mariachi", cast: ["Foo Bar"]))
    contextV3.insert(SchemaV3._Movie(id: uuid(), title: "The Way We Were", cast: ["Babs Strei", "Bob Woodward"]))
    contextV3.insert(SchemaV3._Movie(id: uuid(), title: "Le Monde", cast: ["Côme Hier"]))
    contextV3.insert(SchemaV3._Movie(id: uuid(), title: "Las Escuela", cast: ["Maria", "Foo Bar"]))
    contextV3.insert(SchemaV3._Movie(id: uuid(), title: "La Piscine", cast: ["Valerie", "Bob Woodward", "Babs Strei"]))
    contextV3.insert(SchemaV3._Movie(id: uuid(), title: "A Time To Die", cast: ["Ralph", "Mary"]))
    contextV3.insert(SchemaV3._Movie(id: uuid(), title: "Los Hermanos", cast: ["Harrison"]))
    contextV3.insert(SchemaV3._Movie(id: uuid(), title: "Les Enfants", cast: ["Zoe"]))
    try! contextV3.save()
    let moviesV3 = try! contextV3.fetch(FetchDescriptor<SchemaV3._Movie>(sortBy: [.init(\.title, order: .forward)]))
    #expect(moviesV3[0].title == "A Time To Die")
    #expect(moviesV3[1].title == "El Mariachi")

    // Migrate to V4
    let schemaV4 = Schema(versionedSchema: SchemaV4.self)
    let configV4 = ModelConfiguration(schema: schemaV4, url: url)
    let containerV4 = try! ModelContainer(for: schemaV4, migrationPlan: MockMigrationPlanV4.self,
                                          configurations: configV4)

    let contextV4 = ModelContext(containerV4)
    let moviesV4 = try! contextV4.fetch(FetchDescriptor<SchemaV4._Movie>(sortBy: [
      .init(\.sortableTitle, order: .forward)
    ]))

    #expect(moviesV4.count == moviesV3.count)
    #expect(moviesV4[0].title == "Les Enfants")
    #expect(moviesV4[0].actors.count == 1)
    #expect(moviesV4[0].actors[0].name == "Zoe")

    #expect(moviesV4.count == moviesV3.count)
    #expect(moviesV4[7].title == "The Way We Were")
    #expect(moviesV4[7].actors.count == 2)
    #expect(moviesV4[7].actors[0].name == "Babs Strei")

    let actorsV4 = try! contextV4.fetch(FetchDescriptor<SchemaV4._Actor>(sortBy: [
      .init(\.name, order: .forward)
    ]))

    #expect(actorsV4.count == 10)
    #expect(actorsV4[0].name == "Babs Strei")
    #expect(actorsV4[0].movies.count == 2)
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
      .custom(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self,
        willMigrate: MigrationPlan.moviesV3ToJSON(context:),
        didMigrate: MigrationPlan.jsonToMoviesV4(context:)
      ),
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
