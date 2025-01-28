// From https://github.com/pointfreeco/swift-sharing/tree/main/Examples/GRDBDemo

import Dependencies


public struct FetchKeyID: Hashable {
  let rawValue: AnyHashableSendable

  public init(rawValue: any FetchKeyRequest) {
    self.rawValue = AnyHashableSendable(rawValue)
  }
}
