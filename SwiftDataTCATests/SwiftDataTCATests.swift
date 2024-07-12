import Foundation
import SwiftData
import Testing
@testable import SwiftDataTCA


struct SwiftDataTCATests {

  @Test func testSortableTitle() async throws {
    #expect("world according to garp" == MovieSchemaV3.Movie.sortableTitle("The World According to Garp"))
    #expect("mariachi" == MovieSchemaV3.Movie.sortableTitle("El Mariachi"))
    #expect("way we were" == MovieSchemaV3.Movie.sortableTitle("The Way We Were"))
    #expect("monde" == MovieSchemaV3.Movie.sortableTitle("LE MONDE"))
    #expect("escuela" == MovieSchemaV3.Movie.sortableTitle("LAs Escuela"))
    #expect("time to die" == MovieSchemaV3.Movie.sortableTitle("a Time To Die"))
    #expect("hermanos" == MovieSchemaV3.Movie.sortableTitle("lOs Hermanos"))
    #expect("piscine" == MovieSchemaV3.Movie.sortableTitle("LA piscine"))
  }

  @Test func testMigrationV2V3() async throws {
    // Create V2 database
    let url = FileManager.default.temporaryDirectory.appending(component: "Model.sqlite")
    try? FileManager.default.removeItem(at: url)

    let schemaV2 = Schema(versionedSchema: MovieSchemaV2.self)
    let configV2 = ModelConfiguration(schema: schemaV2, url: url)
    let containerV2 = try! ModelContainer(for: MovieSchemaV2.Movie.self,
                                          migrationPlan: nil,
                                          configurations: configV2)
    let contextV2 = await containerV2.mainContext
    contextV2.insert(Movie(title: "El Mariachi", cast: ["Roberto"]))
    contextV2.insert(Movie(title: "The Way We Were", cast: ["Babs", "Roberto"]))
    contextV2.insert(Movie(title: "Le Monde", cast: ["Côme"]))
    contextV2.insert(Movie(title: "Las Escuela", cast: ["Maria"]))
    contextV2.insert(Movie(title: "La Piscine", cast: ["Valerie"]))
    contextV2.insert(Movie(title: "A Time To Die", cast: ["Ralph", "Mary"]))
    contextV2.insert(Movie(title: "Los Hermanos", cast: ["Harrison"]))
    contextV2.insert(Movie(title: "Les Enfants", cast: ["Zoe"]))
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
}
