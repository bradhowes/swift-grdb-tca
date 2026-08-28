import Dependencies
import Foundation
import IdentifiedCollections
import SQLiteData
import Tagged

@Table
nonisolated public struct Movie: Hashable, Identifiable, Sendable {
  public typealias ID = Tagged<Self, Int64>

  public let id: ID
  public let title: String
  public let sortableTitle: String
  public var favorite: Bool

  public var actorNames: String {
    @Dependency(\.defaultDatabase) var database
    return (try? database.read { db in
      try MovieActorsQuery(movie: self).fetch(db)
        .map { $0.name }
        .joined(separator: ", ")
    }) ?? ""
  }
}

extension Updates<Movie> {
  mutating func toggleFavorite() {
    self.favorite.toggle()
  }
}

extension Movie {

  static func registerMigration(_ migrator: inout DatabaseMigrator) {
    migrator.registerMigration(Self.tableName) { db in
      try #sql(
      """
      CREATE TABLE "\(raw: Self.tableName)" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "title" TEXT NOT NULL,
        "sortableTitle" TEXT NOT NULL,
        "favorite" INTEGER NOT NULL
      ) STRICT
      """
      )
      .execute(db)
    }
  }

  public static func make(db: Database, title: String) throws -> Movie {
    try Movie.insert {
      Draft(title: title, sortableTitle: title.sortable, favorite: false)
    }
    .returning(\.self)
    .fetchAll(db)[0]
  }

  public static func make(db: Database, entry: (String, [String])) throws -> Movie {
    let movie = try Movie.make(db: db, title: entry.0)
    for name in entry.1 {
      let actor = try Actor.fetchOrCreate(db: db, name: name)
      try MovieActor.make(db: db, movieId: movie.id, actorId: actor.id)
    }
    return movie
  }
}

public typealias MovieCollection = IdentifiedArrayOf<Movie>
