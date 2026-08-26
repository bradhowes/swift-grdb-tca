// Copyright © 2025 Brad Howes. All rights reserved.

import Foundation
import os.log
import SnapshotTesting
import SwiftUI
import Testing

#if canImport(UIKit)
import UIKit
#endif

public enum TestSupport {
  static let log: Logger = .init(category: "TestSupport")
}

extension TestSupport {

  public enum SnapshotConfig {
    case portrait
    case landscape
    case tablet
  }

  @MainActor
  public static func assertSnapshot<V: SwiftUI.View>(
    matching: V,
    size: CGSize? = nil,
    config: SnapshotConfig = .portrait,
    colorScheme: ColorScheme = .dark,
    background: Color = .black,
    fileID: StaticString = #fileID,
    file: StaticString = #filePath,
    testName: StaticString = #function,
    line: Int = #line,
    col: Int = #column,
    tag: String = ""
  ) {
    let uniqueTestName = makeUniqueSnapshotName(testName, tag: tag)
    //    for (key, value) in ProcessInfo.processInfo.environment {
    //      log.info("environment[\(key)]: \(value)")
    //    }

    let width = size?.width ?? config.size.width
    let height = size?.height ?? config.size.height
    let layout: SwiftUISnapshotLayout = .fixed(width: width, height: height)

    let view = SnapshotTestViewWrapper(
      size: .init(width: width, height: height),
      colorScheme: colorScheme,
      background: background
    ) {
      matching
    }

#if os(iOS)

    if let result = SnapshotTesting.verifySnapshot(
      of: view,
      as: .image(
        drawHierarchyInKeyWindow: false,
        layout: layout,
        traits: config.traits
      ),
      named: uniqueTestName,
      record: nil,
      snapshotDirectory: nil,
      fileID: fileID,
      file: file,
      testName: "\(testName)",
      line: UInt(line),
      column: UInt(col)
    ) {
      // Only record failures when not runnng in CI pipeline on Github
      if ProcessInfo.processInfo.isOnGithub {
        log.info("*** \(result)")
      } else {
        Issue.record(
          Comment(rawValue: result),
          sourceLocation: .init(fileID: "\(fileID)", filePath: "\(file)", line: line, column: col)
        )
      }
    }

#endif

  }
}

extension TestSupport {

  @inlinable
  static func makeUniqueSnapshotName(_ funcName: StaticString, tag: String) -> String {
#if os(iOS)
    "\(funcName)\(tag)-iOS"
#endif // os(iOS)
#if os(macOS)
    "\(funcName)\(tag)-macOS"
#endif // os(macOS)
  }

  private struct SnapshotTestViewWrapper<Content: View>: View {
    let size: CGSize
    let content: Content
    let colorScheme: ColorScheme
    let background: Color

    public init(size: CGSize, colorScheme: ColorScheme, background: Color?, @ViewBuilder _ content: () -> Content) {
      self.size = size
      self.content = content()
      self.colorScheme = colorScheme
      self.background = background ?? (colorScheme == .dark ? .black : .white)
    }

    public var body: some View {
      Group {
        content
      }
      .frame(width: size.width, height: size.height)
      .background(background)
      .environment(\.colorScheme, colorScheme)
    }
  }
}

extension ProcessInfo {
  public var isOnGithub: Bool { !(environment["SNAPSHOT_ARTIFACTS"]?.isEmpty ?? true) }
}

extension TestSupport.SnapshotConfig {

  public var size: CGSize {
    switch self {
    case .landscape: return .init(width: 800, height: 400)
    case .portrait: return .init(width: 400, height: 800)
    case .tablet: return .init(width: 800, height: 800)
    }
  }

#if os(iOS)

  private func sharedTraits(_ mutations: inout any UIMutableTraits) {
    mutations.layoutDirection = .leftToRight
    mutations.preferredContentSizeCategory = .medium
    mutations.userInterfaceIdiom = .phone
  }

  public var traits: UITraitCollection {
    switch self {
    case .landscape: return .init(
      mutations: {
        sharedTraits(&$0)
        $0.horizontalSizeClass = .regular
        $0.verticalSizeClass = .compact
      }
    )

    case .portrait: return .init(
      mutations: {
        sharedTraits(&$0)
        $0.horizontalSizeClass = .compact
        $0.verticalSizeClass = .regular
      }
    )

    case .tablet: return .init(
      mutations: {
        sharedTraits(&$0)
        $0.horizontalSizeClass = .regular
        $0.verticalSizeClass = .regular
      }
    )
    }
  }

#endif

}
