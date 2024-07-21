import SnapshotTesting
import SwiftUI
import XCTest

extension XCTest {

  @inlinable
  func makeUniqueSnapshotName(_ funcName: String) -> String {
    let platform: String
    platform = "iOS"
    return funcName + "-" + platform
  }

  @inlinable
  func assertSnapshot<V: SwiftUI.View>(
    matching: V, 
    size: CGSize = CGSize(width: 320, height: 480),
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
  ) throws {
    // isRecording = false
    print(ProcessInfo.processInfo.environment)
    let isOnGithub = ProcessInfo.processInfo.environment["CFFIXED_USER_HOME"]?.contains("/Users/runner/Library") ?? false

#if os(iOS)
    if let result = SnapshotTesting.verifySnapshot(
      of: matching,
      as: .image(drawHierarchyInKeyWindow: false, layout: .fixed(width: size.width, height: size.height)),
      named: makeUniqueSnapshotName(testName),
      file: file, testName: testName, line: line
    ) {
      if isOnGithub {
        print("***", result)
      } else {
        XCTFail(result, file: file, line: line)
      }
    }
#endif
  }
}
