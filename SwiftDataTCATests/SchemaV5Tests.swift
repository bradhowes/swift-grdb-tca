#if canImport(Testing)

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import SwiftDataTCA


struct SchemaV5Tests {

  /// NOTE to self: do not use `await container.mainContext` in tests
  /// NOTE to self: do not run Swift Data tests in parallel

  @Test("Creating V5 DB", .disabled("causes crash"))
  func creatingV5Database() async throws {
    let schema = Schema(versionedSchema: SchemaV5.self)
    let config = ModelConfiguration("V55555", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = ModelContext(container)

    let m1 = SchemaV5._Movie(title: "The First Movie")
    context.insert(m1)
    let m2 = SchemaV5._Movie(title: "A Second Movie")
    context.insert(m2)
    let m3 = SchemaV5._Movie(title: "El Third Movie")
    context.insert(m3)
    let a1 = SchemaV5._Actor(name: "Actor 1")
    context.insert(a1)
    let a2 = SchemaV5._Actor(name: "Actor 2")
    context.insert(a2)
    let a3 = SchemaV5._Actor(name: "Actor 3")
    context.insert(a3)
    let a4 = SchemaV5._Actor(name: "Actor 4")
    context.insert(a4)

    try! context.save()

    m1.addActor(a1)
    m1.addActor(a2)
    m1.addActor(a3)

    m2.addActor(a1)
    m2.addActor(a4)

    m3.addActor(a2)

    try! context.save()

    let movies = try! context.fetch(FetchDescriptor<SchemaV5._Movie>(sortBy: [.init(\.sortableTitle, order: .forward)]))

    #expect(movies.count == 3)
    #expect(movies[0].title == "The First Movie")
    #expect(movies[1].title == "A Second Movie")
    #expect(movies[2].title == "El Third Movie")
    #expect(movies[0].actors.count == 3)
    #expect(movies[0].actors[0].movies.contains(movies[0]))
    #expect(movies[1].actors.count == 2)
    #expect(movies[2].actors.count == 1)

    let actors = try! context.fetch(FetchDescriptor<SchemaV5._Actor>(sortBy: [.init(\.name, order: .forward)]))

    #expect(actors.count == 4)
    #expect(actors[0].name == "Actor 1")
    #expect(actors[1].name == "Actor 2")
    #expect(actors[2].name == "Actor 3")
    #expect(actors[3].name == "Actor 4")
    #expect(actors[0].movies.count == 2)
    #expect(actors[0].movies[0].actors.contains(actors[0]))
    #expect(actors[0].movies[1].actors.contains(actors[0]))
  }

  @Test("Migrating from V4 to V5", .disabled("causes crash"))
  func migrationV4V5() async throws {
    let url = FileManager.default.temporaryDirectory.appending(component: "Model5.sqlite")
    try? FileManager.default.removeItem(at: url)

    let schemaV4 = Schema(versionedSchema: SchemaV4.self)
    let configV4 = ModelConfiguration(schema: schemaV4, url: url)
    let containerV4 = try! ModelContainer(for: schemaV4, migrationPlan: nil, configurations: configV4)

    @Dependency(\.uuid) var uuid
    let contextV4 = ModelContext(containerV4)
    contextV4.insert(SchemaV3._Movie(id: uuid(), title: "El Mariachi", cast: ["Foo Bar"]))
    contextV4.insert(SchemaV3._Movie(id: uuid(), title: "The Way We Were", cast: ["Babs Strei", "Bob Woodward"]))
    contextV4.insert(SchemaV3._Movie(id: uuid(), title: "Le Monde", cast: ["Côme Hier"]))
    contextV4.insert(SchemaV3._Movie(id: uuid(), title: "Las Escuela", cast: ["Maria", "Foo Bar"]))
    contextV4.insert(SchemaV3._Movie(id: uuid(), title: "La Piscine", cast: ["Valerie", "Bob Woodward", "Babs Strei"]))
    contextV4.insert(SchemaV3._Movie(id: uuid(), title: "A Time To Die", cast: ["Ralph", "Mary"]))
    contextV4.insert(SchemaV3._Movie(id: uuid(), title: "Los Hermanos", cast: ["Harrison"]))
    contextV4.insert(SchemaV3._Movie(id: uuid(), title: "Les Enfants", cast: ["Zoe"]))
    try! contextV4.save()
    let moviesV4 = try! contextV4.fetch(FetchDescriptor<SchemaV4._Movie>(sortBy: [.init(\.title, order: .forward)]))
    #expect(moviesV4[0].title == "A Time To Die")
    #expect(moviesV4[1].title == "El Mariachi")

    // Migrate to V5
    let schemaV5 = Schema(versionedSchema: SchemaV5.self)
    let configV5 = ModelConfiguration(schema: schemaV5, url: url)
    let containerV5 = try! ModelContainer(for: schemaV5, migrationPlan: MockMigrationPlanV5.self,
                                          configurations: configV5)

    let contextV5 = ModelContext(containerV5)
    let moviesV5 = try! contextV5.fetch(FetchDescriptor<SchemaV5._Movie>(sortBy: [
      .init(\.sortableTitle, order: .forward)
    ]))

    #expect(moviesV5.count == moviesV4.count)
    #expect(moviesV5[0].title == "Les Enfants")
    #expect(moviesV5[0].actors.count == 1)
    #expect(moviesV5[0].actors[0].name == "Zoe")

    #expect(moviesV5[7].title == "The Way We Were")
    #expect(moviesV5[7].actors.count == 2)
    #expect(moviesV5[7].actors[0].name == "Babs Strei" || moviesV5[7].actors[0].name == "Bob Woodward")

    let actorsV5 = try! contextV4.fetch(FetchDescriptor<SchemaV5._Actor>(sortBy: [
      .init(\.name, order: .forward)
    ]))

    #expect(actorsV5.count == 10)
    #expect(actorsV5[0].name == "Babs Strei")
    #expect(actorsV5[0].movies.count == 2)
  }
}

enum MockMigrationPlanV5: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] {
    [
      SchemaV5.self,
    ]
  }

  static var stages: [MigrationStage] {
    [
      StageV5.stage
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
