import Foundation
import SwiftData

enum MigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] {
    [
      SchemaV1.self,
      SchemaV2.self,
      SchemaV3.self,
      SchemaV3.self
    ]
  }

  static var stages: [MigrationStage] {
    [
      .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self),
      .custom(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self,
        willMigrate: nil,
        didMigrate: addSortableTitles(context:)
      ),
      .custom(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self,
        willMigrate: nil,
        didMigrate: populateCast(context:)
      )
    ]
  }

  static func addSortableTitles(context: ModelContext) throws {
    let movies = try context.fetch(FetchDescriptor<SchemaV3.Movie>())
    for movie in movies {
      movie.sortableTitle = Movie.sortableTitle(movie.title)
    }
    try context.save()
  }

  static func populateCast(context: ModelContext) throws {
    let movies = try context.fetch(FetchDescriptor<SchemaV4.Movie>())
    for movie in movies {
      movie.sortableTitle = Movie.sortableTitle(movie.title)
    }
    try context.save()
  }
}
