import Dependencies
import Foundation
import SwiftData

enum MigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] {
    [
      SchemaV1.self,
      SchemaV2.self,
      SchemaV3.self,
      SchemaV4.self
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
        didMigrate: migrateCastToActors(context:)
      )
    ]
  }

  static func addSortableTitles(context: ModelContext) throws {
    let movies = try context.fetch(FetchDescriptor<SchemaV3._Movie>())
    for movie in movies {
      movie.sortableTitle = SchemaV3._Movie.sortableTitle(movie.title)
    }
    try context.save()
  }

  static func migrateCastToActors(context: ModelContext) throws {
    @Dependency(\.uuid) var uuid
    let movies = try context.fetch(FetchDescriptor<SchemaV4._Movie>())
    for movie in movies {
      for name in movie.cast {
        let actor = SchemaV4.fetchOrMakeActor(context, name: name)
        movie.actors.append(actor)
        actor.movies.append(movie)
      }
    }
    try context.save()
  }
}
