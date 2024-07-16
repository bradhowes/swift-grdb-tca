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
        willMigrate: moviesV3ToJSON(context:),
        didMigrate: jsonToMoviesV4(context:)
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

  static func moviesV3ToJSON(context: ModelContext) throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("migration.json")
    let movies = try context.fetch(FetchDescriptor<SchemaV3._Movie>())
    let data = try JSONEncoder().encode(movies)
    try data.write(to: url, options: .atomic)
    for movie in movies {
      context.delete(movie)
    }
    try context.save()
  }

  static func jsonToMoviesV4(context: ModelContext) throws {
    @Dependency(\.uuid) var uuid
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("migration.json")
    let moviesV3 = try JSONDecoder().decode([SchemaV3._Movie].self, from: Data(contentsOf: url))
    for old in moviesV3 {
      let movie = SchemaV4._Movie(id: old.id, title: old.title, favorite: old.favorite)
      print("Old: \(old.title) - \(old.cast)")
      context.insert(movie)
      for name in old.cast {
        let actor = SchemaV4.fetchOrMakeActor(context, name: name)
        movie.actors.append(actor)
        actor.movies.append(movie)
        print("Actor: \(actor.name) - \(actor.movies.map { $0.title })")
      }
      print("New: \(movie.title) - \(movie.actors.map { $0.name })")
    }
    try context.save()
  }
}

extension SchemaV3._Movie: Encodable, Decodable {
  enum CodingKeysV3: CodingKey {
    case id, title, cast, favorite
  }

  convenience init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeysV3.self)
    let id = try container.decode(UUID.self, forKey: .id)
    let title = try container.decode(String.self, forKey: .title)
    let cast = try container.decode(Array<String>.self, forKey: .cast)
    let favorite = try container.decode(Bool.self, forKey: .favorite)
    self.init(id: id, title: title, cast: cast, favorite: favorite)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeysV3.self)
    try container.encode(self.id, forKey: .id)
    try container.encode(self.title, forKey: .title)
    try container.encode(self.cast, forKey: .cast)
    try container.encode(self.favorite, forKey: .favorite)
  }
}
