import ComposableArchitecture
import Dependencies
import Foundation
import SnapshotTesting
import SwiftData
import SwiftUI
import XCTest

@testable import SwiftGRDBTCA

final class AnimationTests: XCTestCase {

  let recording: SnapshotTestingConfiguration.Record = .missing

  @MainActor
  func testFlashDemoPreviewFalse() throws {
    withSnapshotTesting(record: recording) {
      let view = FlashDemoView(isFavorite: false)
      TestSupport.assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testFlashDemoPreviewTrue() throws {
    withSnapshotTesting(record: recording) {
      let view = FlashDemoView(isFavorite: true)
      TestSupport.assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testFadeInDemoPreviewFalse() throws {
    withSnapshotTesting(record: recording) {
      let view = FadeInDemoView(isFavorite: false)
      TestSupport.assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testFadeInDemoPreviewTrue() throws {
    withSnapshotTesting(record: recording) {
      let view = FadeInDemoView(isFavorite: true)
      TestSupport.assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testConfettiDemoPreviewFalse() throws {
    withSnapshotTesting(record: recording) {
      let view = ConfettiDemoView(isFavorite: false)
      TestSupport.assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testConfettiDemoPreviewTrue() throws {
    withSnapshotTesting(record: recording) {
      let view = ConfettiDemoView(isFavorite: true)
      TestSupport.assertSnapshot(matching: view)
    }
  }
}
