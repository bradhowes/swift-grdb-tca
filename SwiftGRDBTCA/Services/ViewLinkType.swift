import Dependencies
import Foundation

/**
 Collection of SwiftData operations one can perform on a "database" regardless of operating environment.
 */
enum LinkKind {
  case button
  case navLink
}

struct ViewLinkType: DependencyKey {
  static let liveValue: LinkKind = .button
}

extension DependencyValues {
  var viewLinkType: LinkKind {
    get { self[ViewLinkType.self] }
    set { self[ViewLinkType.self] = newValue }
  }
}

extension ViewLinkType: TestDependencyKey {
  static let testValue: LinkKind = .navLink
}
