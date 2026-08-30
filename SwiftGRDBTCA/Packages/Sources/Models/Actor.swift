import Dependencies
import Foundation
import IdentifiedCollections
import SQLiteData
import Tagged

@Table
nonisolated public struct Actor: Hashable, Identifiable, Sendable {
  public typealias ID = Tagged<Self, Int64>

  public let id: ID
  public let name: String
}

extension Actor {

  public var movieTitles: String {
    @Dependency(\.defaultDatabase) var database
    return (try? database.read { db in
      try ActorMoviesQuery(actor: self).fetch(db)
        .map { $0.title }
        .joined(separator: ", ")
    }) ?? ""
  }
}

extension Actor {

  static func registerMigration(_ migrator: inout DatabaseMigrator) {
    migrator.registerMigration(Self.tableName) { db in
      try #sql(
      """
      CREATE TABLE "\(raw: Self.tableName)" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "name" TEXT NOT NULL
      ) STRICT
      """
      )
      .execute(db)
    }
  }

  public static func fetchOrCreate(db: Database, name: String) throws -> Actor {
    if let actor = try? Actor.all.where({ $0.name.eq(name) }).fetchOne(db) {
      return actor
    }
    return try Actor.insert {
      Actor.Draft(name: name)
    }
    .returning(\.self)
    .fetchAll(db)[0]
  }
}

public typealias ActorCollection = IdentifiedArrayOf<Actor>
