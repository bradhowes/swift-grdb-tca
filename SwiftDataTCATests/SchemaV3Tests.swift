#if canImport(Testing)

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import SwiftDataTCA


struct SchemaV3Tests {

  /// NOTE to self: do not use `await container.mainContext` in tests
  /// NOTE to self: do not run Swift Data tests in parallel

  @Test func sortableTitle() async throws {
    #expect("world according to garp" == SchemaV3._Movie.sortableTitle("The World According to Garp"))
    #expect("mariachi" == SchemaV3._Movie.sortableTitle("El Mariachi"))
    #expect("way we were" == SchemaV3._Movie.sortableTitle("The Way We Were"))
    #expect("monde" == SchemaV3._Movie.sortableTitle("LE MONDE"))
    #expect("escuela" == SchemaV3._Movie.sortableTitle("LAs Escuela"))
    #expect("time to die" == SchemaV3._Movie.sortableTitle("a Time To Die"))
    #expect("hermanos" == SchemaV3._Movie.sortableTitle("lOs Hermanos"))
    #expect("piscine" == SchemaV3._Movie.sortableTitle("LA piscine"))
  }

  @Test func migrationV2V3() async throws {
    let url = FileManager.default.temporaryDirectory.appending(component: "Model3.sqlite")
    try? FileManager.default.removeItem(at: url)

    let schemaV2 = Schema(versionedSchema: SchemaV2.self)
    let configV2 = ModelConfiguration("V2", schema: schemaV2, url: url)
    let containerV2 = try! ModelContainer(for: schemaV2, migrationPlan: nil, configurations: configV2)

    @Dependency(\.uuid) var uuid
    let contextV2 = ModelContext(containerV2)
    contextV2.insert(SchemaV2._Movie(id: uuid(), title: "El Mariachi", cast: ["Roberto"]))
    contextV2.insert(SchemaV2._Movie(id: uuid(), title: "The Way We Were", cast: ["Babs", "Roberto"]))
    contextV2.insert(SchemaV2._Movie(id: uuid(), title: "Le Monde", cast: ["Côme"]))
    contextV2.insert(SchemaV2._Movie(id: uuid(), title: "Las Escuela", cast: ["Maria"]))
    contextV2.insert(SchemaV2._Movie(id: uuid(), title: "La Piscine", cast: ["Valerie"]))
    contextV2.insert(SchemaV2._Movie(id: uuid(), title: "A Time To Die", cast: ["Ralph", "Mary"]))
    contextV2.insert(SchemaV2._Movie(id: uuid(), title: "Los Hermanos", cast: ["Harrison"]))
    contextV2.insert(SchemaV2._Movie(id: uuid(), title: "Les Enfants", cast: ["Zoe"]))
    try! contextV2.save()
    let moviesV2 = try! contextV2.fetch(FetchDescriptor<SchemaV2._Movie>(sortBy: [.init(\.title, order: .forward)]))
    #expect(moviesV2[0].title == "A Time To Die")
    #expect(moviesV2[1].title == "El Mariachi")

    let schemaV3 = Schema(versionedSchema: SchemaV3.self)
    let configV3 = ModelConfiguration("migrationV2V3", schema: schemaV3, url: url)
    let containerV3 = try! ModelContainer(for: schemaV3, migrationPlan: MockMigrationPlanV3.self, configurations: configV3)
    let contextV3 = ModelContext(containerV3)
    let moviesV3 = try! contextV3.fetch(FetchDescriptor<SchemaV3._Movie>(sortBy: [.init(\.sortableTitle, order: .forward)]))

    #expect(moviesV3[0].sortableTitle == "enfants")
    #expect(moviesV3[0].title == "Les Enfants")
    #expect(moviesV3[1].sortableTitle == "escuela")
    #expect(moviesV3[1].title == "Las Escuela")
    #expect(moviesV3.last!.title == "The Way We Were")
  }

  @Test func creatingV3Database() async throws {
    let schema = Schema(versionedSchema: SchemaV3.self)
    print(schema.entitiesByName)
    let config = ModelConfiguration("creatingV3Database", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = ModelContext(container)

    @Dependency(\.uuid) var uuid
    let m1 = SchemaV3._Movie(id: uuid(), title: "The First Movie", cast: ["Actor 1", "Actor 2", "Actor 3"])
    context.insert(m1)
    let m2 = SchemaV3._Movie(id: uuid(), title: "A Second Movie", cast: ["Actor 1", "Actor 4"])
    context.insert(m2)
    let m3 = SchemaV3._Movie(id: uuid(), title: "El Third Movie", cast: ["Actor 2"])
    context.insert(m3)

    try! context.save()

    let movies = try! context.fetch(FetchDescriptor<SchemaV3._Movie>(sortBy: [.init(\.sortableTitle, order: .forward)]))
    print(movies.map { $0.sortableTitle })
    print(movies.map { $0.title })

    #expect(movies.count == 3)
    #expect(movies[0].title == "The First Movie")
    #expect(movies[1].title == "A Second Movie")
    #expect(movies[2].title == "El Third Movie")

    #expect(movies[0].cast.count == 3)
    #expect(movies[0].cast[0] == "Actor 1")
  }

  @Test func movieMock() async {
    withDependencies {
      $0.withRandomNumberGenerator = .init(LCRNG(seed: 0))
    } operation: {
      #expect(SchemaV3._Movie.mock.title == "Avatar")
      #expect(SchemaV3._Movie.mock.title == "After Earth")
    }
  }
}

enum MockMigrationPlanV3: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] {
    [
      SchemaV3.self,
    ]
  }

  static var stages: [MigrationStage] {
    [
      .custom(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self,
        willMigrate: nil,
        didMigrate: MigrationPlan.addSortableTitles(context:)
      )
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
