import GRDB


public protocol FetchKeyRequest<Value>: Hashable, Sendable {
  associatedtype Value

  func fetch(_ db: Database) throws -> Value
}
