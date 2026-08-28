import Dependencies
import Foundation
import IdentifiedCollections
import SQLiteData
import Tagged

@Table
nonisolated public struct ActorText {
  public let actorId: Actor.ID
  public let name: String
}

extension ActorText: FTS5 {
  static let tokenizer = "porter unicode61 remove_diacritics 1"

  static func registerMigration(_ migrator: inout DatabaseMigrator) {
    migrator.registerMigration(Self.tableName) { db in
      try #sql(
        """
        CREATE VIRTUAL TABLE "\(raw: Self.tableName)" USING FTS5 (
          "actorId" UNINDEXED,
          "name",
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

extension ActorText {

  private static func registerInsertTrigger(_ db: Database) throws {
    try Actor.createTemporaryTrigger(
      after: .insert { new in
        ActorText.insert {
          ActorText.Columns(
            actorId: new.id,
            name: new.name
          )
        }
      }
    ).execute(db)
  }

  private static func registerUpdateTrigger(_ db: Database) throws {
    try Actor.createTemporaryTrigger(
      after: .update {
        ($0.name)
      } forEachRow: { _, new in
        ActorText
          .where { $0.actorId.eq(new.id) }
          .update {
            $0.name = new.name
          }
      }
    ).execute(db)
  }

  private static func registerDeleteTrigger(_ db: Database) throws {
    try Actor.createTemporaryTrigger(
      after: .delete { old in
        ActorText
          .where { $0.actorId.eq(old.id) }
          .delete()
      }
    ).execute(db)
  }
}
