#if canImport(Testing)

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import SwiftDataTCA

struct SchemaV1Tests {

  /// NOTE to self: do not use `await container.mainContext` in tests
  /// NOTE to self: do not run Swift Data tests in parallel

  @Test func creatingV1Database() async throws {
    withDependencies {
      $0.uuid = .incrementing
    } operation: {

      let schema = Schema(versionedSchema: SchemaV1.self)
      let config = ModelConfiguration("V1", schema: schema, isStoredInMemoryOnly: true)
      let container = try! ModelContainer(for: schema, configurations: config)
      let context = ModelContext(container)

      @Dependency(\.uuid) var uuid

      let m = SchemaV1._Movie(id: uuid(), title: "The Way We Were", cast: ["Barbara Streisand", "Robert Redford"])
      context.insert(m)
      try! context.save()

      #expect(m.id == UUID(0))
      #expect(m.title == "The Way We Were")
      #expect(m.cast.count == 2)
    }
  }
}

#endif
