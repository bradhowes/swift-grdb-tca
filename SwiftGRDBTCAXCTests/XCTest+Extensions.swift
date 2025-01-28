import Dependencies
import SnapshotTesting
import SwiftData
import SwiftUI
import XCTest

@testable import SwiftDataTCA

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
    size: CGSize = CGSize(width: 640, height: 1136),
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
  ) throws {
    // isRecording = true
    let isOnGithub = ProcessInfo.processInfo.environment["CFFIXED_USER_HOME"]?.contains("/Users/runner/Library") ?? false

#if os(iOS)
    if let result = SnapshotTesting.verifySnapshot(
      of: matching,
      as: .image(
        drawHierarchyInKeyWindow: false,
        precision: 0.8,
        perceptualPrecision: 0.8,
        layout: .fixed(width: size.width, height: size.height)
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

extension XCTestCase {
  
  /**
   Create a ModelContext for a given schema. Supports migration via JSON file.

   - parameter versionedSchema the schema to support
   - parameter migrationPlan optional migration plan to follow if migration from previous schema
   - parameter storage optional URL to use for storage. If nil, create in-memory database
   */
  func makeContext(
    _ verseionedSchema: any VersionedSchema.Type,
    migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
    storage: URL? = nil
  ) -> ModelContext {
    let schema = Schema(versionedSchema: verseionedSchema.self)
    let config: ModelConfiguration
    if let url = storage {
      config = ModelConfiguration(schema: schema, url: url)
    } else {
      config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    }
    let container = try! ModelContainer(for: schema, migrationPlan: migrationPlan, configurations: config)
    return ModelContext(container)
  }

  /**
   Tear down a database by deleting everything associated with the container for a ModelContext

   - parameter context the ModelContext to delete
   */
  func cleanup(_ context: ModelContext) {
    context.container.deleteAllData()
  }

  func withNewContext(
    _ verseionedSchema: any VersionedSchema.Type,
    migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
    storage: URL? = nil,
    block: (ModelContext) -> Void
  ) {
    let context = makeContext(verseionedSchema, migrationPlan: migrationPlan, storage: storage)
    defer { if storage == nil { cleanup(context) } }
    withDependencies {
      $0.modelContextProvider = context
    } operation: {
      block(context)
    }
  }
}
