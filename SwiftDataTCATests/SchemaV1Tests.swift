#if canImport(Testing)

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import SwiftDataTCA

struct SchemaV1Tests {
  typealias ActiveSchema = SchemaV1

  /// NOTE to self: do not use `await container.mainContext` in tests
  /// NOTE to self: do not run Swift Data tests in parallel

  @Test func creatingV1Database() async throws {
    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      let context = TestingSupport.makeContext(ActiveSchema.self)
      defer { TestingSupport.cleanup(context) }
      @Dependency(\.uuid) var uuid

      let m = ActiveSchema._Movie(id: uuid(), title: "The Way We Were", cast: ["Barbara Streisand", "Robert Redford"])
      context.insert(m)
      try! context.save()

      #expect(m.id == UUID(0))
      #expect(m.title == "The Way We Were")
      #expect(m.cast.count == 2)
    }
  }
}

#endif
