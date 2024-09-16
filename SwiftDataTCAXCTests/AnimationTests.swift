import ComposableArchitecture
import Dependencies
import Foundation
import SnapshotTesting
import SwiftData
import SwiftUI
import XCTest

@testable import SwiftDataTCA

final class AnimationTests: XCTestCase {

  @MainActor
  func testFlashDemoPreviewFalse() throws {
    try withSnapshotTesting(record: .failed) {
      let view = FlashDemoView(isFavorite: false)
      try assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testFlashDemoPreviewTrue() throws {
    try withSnapshotTesting(record: .failed) {
      let view = FlashDemoView(isFavorite: true)
      try assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testFadeInDemoPreviewFalse() throws {
    try withSnapshotTesting(record: .failed) {
      let view = FadeInDemoView(isFavorite: false)
      try assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testFadeInDemoPreviewTrue() throws {
    try withSnapshotTesting(record: .failed) {
      let view = FadeInDemoView(isFavorite: true)
      try assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testConfettiDemoPreviewFalse() throws {
    try withSnapshotTesting(record: .failed) {
      let view = ConfettiDemoView(isFavorite: false)
      try assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testConfettiDemoPreviewTrue() throws {
    try withSnapshotTesting(record: .failed) {
      let view = ConfettiDemoView(isFavorite: true)
      try assertSnapshot(matching: view)
    }
  }
}
