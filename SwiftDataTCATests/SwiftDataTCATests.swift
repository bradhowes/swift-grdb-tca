#if canImport(Testing)

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import SwiftDataTCA


struct SwiftDataTCATests {

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
    // Create V2 database
    let url = FileManager.default.temporaryDirectory.appending(component: "Model.sqlite")
    try? FileManager.default.removeItem(at: url)

    let schemaV2 = Schema(versionedSchema: SchemaV2.self)
    let configV2 = ModelConfiguration(schema: schemaV2, url: url)
    let containerV2 = try! ModelContainer(for: SchemaV2._Movie.self, migrationPlan: nil, configurations: configV2)

    @Dependency(\.uuid) var uuid
    let contextV2 = await containerV2.mainContext
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

    // Migrate to V3
    let schemaV3 = Schema(versionedSchema: SchemaV3.self)
    let configV3 = ModelConfiguration(schema: schemaV3, url: url)
    let containerV3 = try! ModelContainer(for: SchemaV3._Movie.self, migrationPlan: MockMigrationPlan.self,
                                          configurations: configV3)

    let contextV3 = await containerV3.mainContext
    let moviesV3 = try! contextV3.fetch(FetchDescriptor<SchemaV3._Movie>(sortBy: [.init(\.sortableTitle, order: .forward)]))

    #expect(moviesV3[0].sortableTitle == "enfants")
    #expect(moviesV3[0].title == "Les Enfants")
    #expect(moviesV3[1].sortableTitle == "escuela")
    #expect(moviesV3[1].title == "Las Escuela")
    #expect(moviesV3.last!.title == "The Way We Were")
  }

  @Test func movieMock() async {
    withDependencies {
      $0.withRandomNumberGenerator = .init(LCRNG(seed: 0))
    } operation: {
      #expect(SchemaV3._Movie.mock.title == "Avatar")
      #expect(SchemaV3._Movie.mock.title == "Hancock")
    }
  }
}

enum MockMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] {
    [
      SchemaV1.self,
      SchemaV2.self,
      SchemaV3.self,
    ]
  }

  static var stages: [MigrationStage] {
    [
      .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self),
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
