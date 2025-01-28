import Dependencies
import Foundation
import SwiftData

@testable import SwiftDataTCA

enum TestingSupport {

  /**
   Create a ModelContext for a given schema. Supports migration via JSON file.

   - parameter versionedSchema the schema to support
   - parameter migrationPlan optional migration plan to follow if migration from previous schema
   - parameter storage optional URL to use for storage. If nil, create in-memory database
   */
  static func makeContext(
    _ verseionedSchema: any VersionedSchema.Type,
    migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
    storage: URL? = nil
  ) -> ModelContext {
    let schema = Schema(versionedSchema: verseionedSchema.self)
    let config: ModelConfiguration
    if let url = storage {
      config = ModelConfiguration(schema: schema, url: url)
    } else {
      config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    }
    let container = try! ModelContainer(for: schema, migrationPlan: migrationPlan, configurations: config)
    return ModelContext(container)
  }

  /**
   Tear down a database by deleting everything associated with the container for a ModelContext

   - parameter context the ModelContext to delete
   */
  static func cleanup(_ context: ModelContext) {
    context.container.deleteAllData()
  }

  static func withNewContext(
    _ verseionedSchema: any VersionedSchema.Type,
    migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
    storage: URL? = nil,
    block: (ModelContext) -> Void
  ) {
    let context = makeContext(verseionedSchema, migrationPlan: migrationPlan, storage: storage)
    defer { if storage == nil { cleanup(context) } }
    withDependencies {
      $0.modelContextProvider = context
    } operation: {
      block(context)
    }
  }
}
