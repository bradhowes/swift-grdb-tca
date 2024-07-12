import Foundation

enum SwiftDataTCA {
  static var previewing: Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
  }
}
