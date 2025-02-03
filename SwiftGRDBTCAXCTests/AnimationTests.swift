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
      assertSnapshot(of: view, as: .image)
    }
  }

  @MainActor
  func testFlashDemoPreviewTrue() throws {
    withSnapshotTesting(record: recording) {
      let view = FlashDemoView(isFavorite: true)
      assertSnapshot(of: view, as: .image)
    }
  }

  @MainActor
  func testFadeInDemoPreviewFalse() throws {
    withSnapshotTesting(record: recording) {
      let view = FadeInDemoView(isFavorite: false)
      assertSnapshot(of: view, as: .image)
    }
  }

  @MainActor
  func testFadeInDemoPreviewTrue() throws {
    withSnapshotTesting(record: recording) {
      let view = FadeInDemoView(isFavorite: true)
      assertSnapshot(of: view, as: .image)
    }
  }

  @MainActor
  func testConfettiDemoPreviewFalse() throws {
    withSnapshotTesting(record: recording) {
      let view = ConfettiDemoView(isFavorite: false)
      assertSnapshot(of: view, as: .image)
    }
  }

  @MainActor
  func testConfettiDemoPreviewTrue() throws {
    withSnapshotTesting(record: recording) {
      let view = ConfettiDemoView(isFavorite: true)
      assertSnapshot(of: view, as: .image)
    }
  }
}
