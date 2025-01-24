import Dependencies
import GRDB
import Sharing
import SwiftUI


public extension SharedReaderKey {
  /// A key that can query for data in a SQLite database.
  static func fetch<Value>(
    _ request: some FetchKeyRequest<Value>,
    database: (any DatabaseReader)? = nil,
    animation: Animation? = nil
  ) -> Self
  where Self == FetchKey<Value> {
    FetchKey(request: request, database: database, animation: animation)
  }

  /// A key that can query for a collection of data in a SQLite database.
  static func fetch<Value: RangeReplaceableCollection>(
    _ request: some FetchKeyRequest<Value>,
    database: (any DatabaseReader)? = nil,
    animation: Animation? = nil
  ) -> Self
  where Self == FetchKey<Value>.Default {
    Self[.fetch(request, database: database, animation: animation), default: Value()]
  }

  /// A key that can query for a collection of data in a SQLite database.
  static func fetchAll<Value: FetchableRecord>(
    query: QueryInterfaceRequest<Value>,
    database: (any DatabaseReader)? = nil,
    animation: Animation? = nil
  ) -> Self
  where Self == FetchKey<[Value]>.Default {
    Self[.fetch(FetchAll(query: query, database: database), database: database, animation: animation), default: []]
  }

  /// A key that can query for a value in a SQLite database.
  static func fetchOne<Value: DatabaseValueConvertible>(
    query: QueryInterfaceRequest<Value>,
    database: any DatabaseReader,
    animation: Animation? = nil
  ) throws -> Self
  where Self == FetchKey<Value> {
    try .fetch(FetchOne(query: query, database: database), database: database, animation: animation)
  }
}

private struct FetchAll<Element: FetchableRecord>: FetchKeyRequest {
  var sql: String

  init(query: QueryInterfaceRequest<Element>, database: (any DatabaseReader)? = nil) {
    @Dependency(\.defaultDatabase) var defaultDatabase
    let databaseReader = database ?? defaultDatabase
    do {
      sql = try databaseReader.read { try query.makePreparedRequest($0).statement.sql }
    } catch {
      fatalError("Failed to prepare SQL from query: \(error)")
    }
  }

  func fetch(_ db: Database) throws -> [Element] {
    try Element.fetchAll(db, sql: sql)
  }
}

private struct FetchOne<Value: DatabaseValueConvertible>: FetchKeyRequest {
  var sql: String

  init(query: QueryInterfaceRequest<Value>, database: any DatabaseReader) throws {
    sql = try database.read { try query.makePreparedRequest($0).statement.sql }
  }

  func fetch(_ db: Database) throws -> Value {
    guard let value = try Value.fetchOne(db, sql: sql) else { throw NotFound() }
    return value
  }

  struct NotFound: Error {}
}

