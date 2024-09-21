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
    delay: TimeInterval = 1.0,
    size: CGSize = CGSize(width: 320, height: 480),
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
  ) throws {
    // isRecording = true
    let isOnGithub = ProcessInfo.processInfo.environment["CFFIXED_USER_HOME"]?.contains("/Users/runner/Library") ?? false

#if os(iOS)
    if let result = SnapshotTesting.verifySnapshot(
      of: matching,
      as: .wait(
        for: delay,
        on: .image(
          drawHierarchyInKeyWindow: false,
          precision: 0.8,
          perceptualPrecision: 0.8,
          layout: .fixed(width: size.width, height: size.height))
      ),
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
