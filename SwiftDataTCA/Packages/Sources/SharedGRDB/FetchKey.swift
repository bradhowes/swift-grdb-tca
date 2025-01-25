// From https://github.com/pointfreeco/swift-sharing/tree/main/Examples/GRDBDemo

@preconcurrency import Combine
import Dependencies
import GRDB
import Sharing
import SwiftUI


public struct FetchKey<Value: Sendable>: SharedReaderKey {
  public typealias ID = FetchKeyID

  let database: any DatabaseReader
  let request: any FetchKeyRequest<Value>
  let scheduler: any ValueObservationScheduler

#if DEBUG
  let isDefaultDatabase: Bool
#endif

  public var id: ID { ID(rawValue: request) }

  public init(request: some FetchKeyRequest<Value>, database: (any DatabaseReader)? = nil, animation: Animation? = nil) {
    @Dependency(\.defaultDatabase) var defaultDatabase
    self.scheduler = .animation(animation)
    self.database = database ?? defaultDatabase
    self.request = request
#if DEBUG
    self.isDefaultDatabase = self.database.configuration.label == .defaultDatabaseLabel
#endif
  }

  public func load(context: LoadContext<Value>, continuation: LoadContinuation<Value>) {
    print("FetchKey.load")
#if DEBUG
    guard !isDefaultDatabase else {
      print("FetchKey isDefaultDatabase")
      return continuation.resumeReturningInitialValue()
    }
#endif

    guard case .userInitiated = context else {
      print("FetchKey userInitiated")
      return continuation.resumeReturningInitialValue()
    }

    guard !isTesting else {
      print("FetchKey isTesting")
      return continuation.resume(with: Result { try database.read(request.fetch) })
    }

    database.asyncRead { dbResult in
      let result = dbResult.flatMap { db in
        Result { try request.fetch(db) }
      }
      scheduler.schedule { continuation.resume(with: result.map(Optional.some)) }
    }
  }

  public func subscribe(context: LoadContext<Value>, subscriber: SharedSubscriber<Value>) -> SharedSubscription {
#if DEBUG
    guard !isDefaultDatabase else {
      return SharedSubscription {}
    }
#endif

    let observation = ValueObservation.tracking(request.fetch)

    let dropFirst = switch context {
    case .initialValue: false
    case .userInitiated: true
    }

    let cancellable = observation.publisher(in: database, scheduling: scheduler)
      .dropFirst(dropFirst ? 1 : 0)
      .sink { completion in
        switch completion {
        case let .failure(error): subscriber.yield(throwing: error)
        case .finished: break
        }
      } receiveValue: { newValue in
        subscriber.yield(newValue)
      }

    return SharedSubscription {
      cancellable.cancel()
    }
  }
}

#if DEBUG
extension String {
  static let defaultDatabaseLabel = "co.pointfree.SharingGRDB.testValue"
}
#endif
