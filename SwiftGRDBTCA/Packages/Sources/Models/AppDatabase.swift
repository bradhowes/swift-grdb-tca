import Dependencies
import Foundation
import GRDB
import Sharing
import SQLite3
import SQLiteData

// swiftlint:disable:next function_body_length
public func appDatabase(
  rowCount: Int = 100,
  seeder: (@Sendable (Database) throws -> Void)? = nil
) throws -> any DatabaseWriter {
  @Dependency(\.context) var context

  var configuration = GRDB.Configuration()
  configuration.foreignKeysEnabled = true
  configuration.prepareDatabase { db in
    db.trace(options: .profile) {
      print("\($0.expandedDescription)")
    }
  }

  let database = try SQLiteData.defaultDatabase(configuration: configuration)
  print("App database:\nopen \(database.path)")

  try performMigrations(
    database,
    rowCount: rowCount,
    seeder: seeder
  )

  return database
}

private func performMigrations(
  _ database: any DatabaseWriter,
  rowCount: Int,
  seeder: (@Sendable (Database) throws -> Void)?
) throws {
  @Dependency(\.context) var context
  var migrator = DatabaseMigrator()

#if DEBUG
  migrator.eraseDatabaseOnSchemaChange = true
#endif // DEBUG

  // NOTE: order is important here.
  Movie.registerMigration(&migrator)
  MovieText.registerMigration(&migrator)
  Actor.registerMigration(&migrator)
  ActorText.registerMigration(&migrator)
  MovieActor.registerMigration(&migrator)

  migrator.registerMigration("seeding") { db in
    try Support.generateRows(db: db, count: rowCount)
    if let seeder {
      try seeder(db)
    }
  }

  try migrator.migrate(database)
}
