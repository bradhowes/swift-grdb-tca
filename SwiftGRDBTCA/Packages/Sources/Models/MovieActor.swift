import Dependencies
import Foundation
import IdentifiedCollections
import SQLiteData
import Tagged

@Table
nonisolated public struct MovieActor: Hashable {
  public let movieId: Movie.ID
  public let actorId: Actor.ID
}

extension MovieActor {

  static func registerMigration(_ migrator: inout DatabaseMigrator) {
    migrator.registerMigration(Self.tableName) { db in
      try #sql(
        """
        CREATE TABLE "\(raw: Self.tableName)" (
          "movieId" INTEGER NOT NULL,
          "actorId" INTEGER NOT NULL,
          PRIMARY KEY("movieId", "actorId"),
          FOREIGN KEY("movieId") REFERENCES "\(raw: Movie.tableName)"("id") ON DELETE CASCADE,
          FOREIGN KEY("actorId") REFERENCES "\(raw: Actor.tableName)"("id") ON DELETE CASCADE
        ) STRICT, WITHOUT ROWID
        """
      )
      .execute(db)
    }
  }

  static func make(db: Database, movieId: Movie.ID, actorId: Actor.ID) throws {
    try MovieActor.insert {
      .init(movieId: movieId, actorId: actorId)
    } onConflictDoUpdate: { _ in }
      .execute(db)
  }
}
