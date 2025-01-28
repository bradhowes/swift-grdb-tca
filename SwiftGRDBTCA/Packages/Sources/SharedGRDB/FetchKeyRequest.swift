// From https://github.com/pointfreeco/swift-sharing/tree/main/Examples/GRDBDemo

import GRDB


public protocol FetchKeyRequest<Value>: Hashable, Sendable {
  associatedtype Value

  func fetch(_ db: Database) throws -> Value
}
