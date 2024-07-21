#if canImport(Testing)

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import SwiftDataTCA

struct SchemaV2Tests {

  /// NOTE to self: do not use `await container.mainContext` in tests
  /// NOTE to self: do not run Swift Data tests in parallel

  @Test func creatingV2Database() async throws {
    let schema = Schema(versionedSchema: SchemaV2.self)
    let config = ModelConfiguration("V2", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = ModelContext(container)

    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      SchemaV2.makeMock(context: context, entry: ("The First Movie", ["Actor 1", "Actor 2", "Actor 3"]))
      SchemaV2.makeMock(context: context, entry: ("A Second Movie", ["Actor 1", "Actor 4"]))
      SchemaV2.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
      try! context.save()
    }

    let movies = try! context.fetch(SchemaV2.movieFetchDescriptor(titleSort: .forward, uuidSort: .none, searchString: ""))

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
  