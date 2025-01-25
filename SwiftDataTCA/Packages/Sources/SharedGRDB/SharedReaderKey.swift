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
}
