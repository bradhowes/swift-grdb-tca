// From https://github.com/pointfreeco/swift-sharing/tree/main/Examples/GRDBDemo

import GRDB
import Sharing
import SwiftUI


public extension SharedReaderKey {
  /// A key that can query for a collection of data in a SQLite database.
  static func fetch<Value: RangeReplaceableCollection>(
    _ request: some FetchKeyRequest<Value>,
    database: (any DatabaseReader)? = nil,
    animation: Animation? = nil
  ) -> Self
  where Self == FetchKey<Value>.Default {
    Self[FetchKey(request: request, database: database, animation: animation), default: Value()]
  }
}
