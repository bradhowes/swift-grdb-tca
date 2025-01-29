import ComposableArchitecture
import Dependencies
import Foundation
import SnapshotTesting
import SwiftData
import SwiftUI
import XCTest

@testable import SwiftGRDBTCA

final class AnimationTests: XCTestCase {

  let recording: SnapshotTestingConfiguration.Record = .failed

  @MainActor
  func testFlashDemoPreviewFalse() throws {
    try withSnapshotTesting(record: recording) {
      let view = FlashDemoView(isFavorite: false)
      try assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testFlashDemoPreviewTrue() throws {
    try withSnapshotTesting(record: recording) {
      let view = FlashDemoView(isFavorite: true)
      try assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testFadeInDemoPreviewFalse() throws {
    try withSnapshotTesting(record: recording) {
      let view = FadeInDemoView(isFavorite: false)
      try assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testFadeInDemoPreviewTrue() throws {
    try withSnapshotTesting(record: recording) {
      let view = FadeInDemoView(isFavorite: true)
      try assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testConfettiDemoPreviewFalse() throws {
    try withSnapshotTesting(record: recording) {
      let view = ConfettiDemoView(isFavorite: false)
      try assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testConfettiDemoPreviewTrue() throws {
    try withSnapshotTesting(record: recording) {
      let view = ConfettiDemoView(isFavorite: true)
      try assertSnapshot(matching: view)
    }
  }
}
