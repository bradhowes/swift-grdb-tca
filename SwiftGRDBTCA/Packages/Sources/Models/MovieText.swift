import Dependencies
import Foundation
import IdentifiedCollections
import SQLiteData
import Tagged

@Table
nonisolated public struct MovieText {
  public let movieId: Movie.ID
  public let title: String
  public let actorNames: String
}

extension MovieText: FTS5 {
  static let tokenizer = "porter unicode61 remove_diacritics 1"
  
  static func registerMigration(_ migrator: inout DatabaseMigrator) {
    migrator.registerMigration(Self.tableName) { db in
      try #sql(
        """
        CREATE VIRTUAL TABLE "\(raw: Self.tableName)" USING FTS5 (
          "movieId" UNINDEXED,
          "title",
          "actorNames",
          tokenize = '\(raw: Self.tokenizer)'
        )
        """
      )
      .execute(db)

      try registerInsertTrigger(db)
      try registerUpdateTrigger(db)
      try registerDeleteTrigger(db)
    }
  }
}

extension MovieText {

  private static func registerInsertTrigger(_ db: Database) throws {
    try Movie.createTemporaryTrigger(
      after: .insert { new in
        MovieText.insert {
          MovieText.Columns(
            movieId: new.id,
            title: new.title,
            actorNames: new.actorNames
          )
        }
      }
    ).execute(db)
  }

  private static func registerUpdateTrigger(_ db: Database) throws {
    try Movie.createTemporaryTrigger(
      after: .update {
        ($0.title)
      } forEachRow: { _, new in
        MovieText
          .where { $0.movieId.eq(new.id) }
          .update {
            $0.title = new.title
            $0.actorNames = new.actorNames
          }
      }
    ).execute(db)
  }

  private static func registerDeleteTrigger(_ db: Database) throws {
    try Movie.createTemporaryTrigger(
      after: .delete { old in
        MovieText
          .where { $0.movieId.eq(old.id) }
          .delete()
      }
    ).execute(db)
  }
}
