import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import SwiftDataTCA


struct SwiftDataTCATests {

  @Test func sortableTitle() async throws {
    #expect("world according to garp" == MovieSchemaV3.Movie.sortableTitle("The World According to Garp"))
    #expect("mariachi" == MovieSchemaV3.Movie.sortableTitle("El Mariachi"))
    #expect("way we were" == MovieSchemaV3.Movie.sortableTitle("The Way We Were"))
    #expect("monde" == MovieSchemaV3.Movie.sortableTitle("LE MONDE"))
    #expect("escuela" == MovieSchemaV3.Movie.sortableTitle("LAs Escuela"))
    #expect("time to die" == MovieSchemaV3.Movie.sortableTitle("a Time To Die"))
    #expect("hermanos" == MovieSchemaV3.Movie.sortableTitle("lOs Hermanos"))
    #expect("piscine" == MovieSchemaV3.Movie.sortableTitle("LA piscine"))
  }

  @Test func migrationV2V3() async throws {
    // Create V2 database
    let url = FileManager.default.temporaryDirectory.appending(component: "Model.sqlite")
    let entry = mockData.randomElement()!
    try? FileManager.default.removeItem(at: url)

    let schemaV2 = Schema(versionedSchema: MovieSchemaV2.self)
    let configV2 = ModelConfiguration(schema: schemaV2, url: url)
    let containerV2 = try! ModelContainer(for: MovieSchemaV2.Movie.self,
                                          migrationPlan: nil,
                                          configurations: configV2)

    @Dependency(\.uuid) var uuid
    let contextV2 = await containerV2.mainContext
    contextV2.insert(Movie(id: uuid(), title: "El Mariachi", cast: ["Roberto"]))
    contextV2.insert(Movie(id: uuid(), title: "The Way We Were", cast: ["Babs", "Roberto"]))
    contextV2.insert(Movie(id: uuid(), title: "Le Monde", cast: ["Côme"]))
    contextV2.insert(Movie(id: uuid(), title: "Las Escuela", cast: ["Maria"]))
    contextV2.insert(Movie(id: uuid(), title: "La Piscine", cast: ["Valerie"]))
    contextV2.insert(Movie(id: uuid(), title: "A Time To Die", cast: ["Ralph", "Mary"]))
    contextV2.insert(Movie(id: uuid(), title: "Los Hermanos", cast: ["Harrison"]))
    contextV2.insert(Movie(id: uuid(), title: "Les Enfants", cast: ["Zoe"]))
    try! contextV2.save()
    let moviesV2 = try! contextV2.fetch(FetchDescriptor<MovieSchemaV2.Movie>(sortBy: [.init(\.title, order: .forward)]))
    #expect(moviesV2[0].title == "A Time To Die")
    #expect(moviesV2[1].title == "El Mariachi")

    // Migrate to V3
    let schemaV3 = Schema(versionedSchema: MovieSchemaV3.self)
    let configV3 = ModelConfiguration(schema: schemaV3, url: url)
    let containerV3 = try! ModelContainer(for: MovieSchemaV3.Movie.self,
                                          migrationPlan: MovieMigrationPlan.self,
                                          configurations: configV3)
    let contextV3 = await containerV3.mainContext
    let moviesV3 = try! contextV3.fetch(FetchDescriptor<MovieSchemaV3.Movie>(sortBy: [.init(\.sortableTitle, order: .forward)]))

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
      #expect(Movie.mock.title == "Avatar")
      #expect(Movie.mock.title == "Hancock")
    }
  }

  @Test func addButtonTapped() async {
    let store = TestStore(initialState: FromStateFeature.State()) {
      FromStateFeature()
    } withDependencies: {
      $0.uuid = .constant(UUID(0))
      $0.withRandomNumberGenerator = .init(LCRNG(seed: 0))
    }

    await store.send(.addButtonTapped) {
      $0.movies = [Movie(id: UUID(0), title: "Avatar", cast: [""])]
    }
  }
}

private struct LCRNG: RandomNumberGenerator {
  var seed: UInt64
  mutating func next() -> UInt64 {
    self.seed = 2_862_933_555_777_941_757 &* self.seed &+ 3_037_000_493
    return self.seed
  }
}
