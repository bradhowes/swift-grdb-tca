#if canImport(Testing)

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import SwiftDataTCA


struct SwiftDataTCATests {

  /// NOTE to self: do not use `await container.mainContext` in tests
  /// NOTE to self: do not run Swift Data tests in parallel

  @Test func creatingV2Database() async throws {
    let schema = Schema(versionedSchema: SchemaV2.self)
    let config = ModelConfiguration("V2", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = ModelContext(container)

    @Dependency(\.uuid) var uuid
    let m1 = SchemaV2._Movie(id: uuid(), title: "The First Movie", cast: ["Actor 1", "Actor 2", "Actor 3"])
    context.insert(m1)
    let m2 = SchemaV2._Movie(id: uuid(), title: "A Second Movie", cast: ["Actor 1", "Actor 4"])
    context.insert(m2)
    let m3 = SchemaV2._Movie(id: uuid(), title: "El Third Movie", cast: ["Actor 2"])
    context.insert(m3)

    try! context.save()

    let movies = try! context.fetch(FetchDescriptor<SchemaV2._Movie>(sortBy: [.init(\.title, order: .forward)]))

    #expect(movies.count == 3)
    #expect(movies[0].title == "A Second Movie")
    #expect(movies[1].title == "El Third Movie")
    #expect(movies[2].title == "The First Movie")

    #expect(movies[0].cast.count == 2)
    #expect(movies[0].cast[0] == "Actor 1")
    #expect(movies[0].cast[1] == "Actor 4")
  }
}

#endif
