import Foundation
import SwiftData

enum MovieMigrationPlan: SchemaMigrationPlan {

  static var schemas: [any VersionedSchema.Type] {
    [
      MovieSchemaV1.self,
      MovieSchemaV2.self,
      MovieSchemaV3.self
    ]
  }

  static var stages: [MigrationStage] {
    [
      .lightweight(fromVersion: MovieSchemaV1.self, toVersion: MovieSchemaV2.self),
      .custom(fromVersion: MovieSchemaV2.self, toVersion: MovieSchemaV3.self,
              willMigrate: nil,
              didMigrate: addSortableTitles(context:))
    ]
  }

  static func addSortableTitles(context: ModelContext) throws {
    let movies = try context.fetch(FetchDescriptor<MovieSchemaV3.Movie>())
    for movie in movies {
      movie.sortableTitle = Movie.sortableTitle(movie.title)
    }
    try context.save()
  }
}
