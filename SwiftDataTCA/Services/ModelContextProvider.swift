import Dependencies
import Foundation
import SwiftData

typealias ActiveSchema = SchemaV6

typealias ActorModel = ActiveSchema.ActorModel
typealias MovieModel = ActiveSchema.MovieModel

typealias Actor = ActiveSchema.Actor
typealias Movie = ActiveSchema.Movie

/**
 Wrapper around a `ModelContext` value that can be used for a dependency.
 */
struct ModelContextProvider {
  /// The context to use for SwiftData operations
  let context: ModelContext
  /// The container associated with the context
  var container: ModelContainer { context.container }
}

extension DependencyValues {
  var modelContextProvider: ModelContext {
    get { self[ModelContextKey.self] }
    set { self[ModelContextKey.self] = newValue }
  }
}

public enum ModelContextKey: DependencyKey {
  public static let liveValue = liveContext()
}

extension ModelContextKey: TestDependencyKey {
  public static var previewValue: ModelContext { previewContext() }
  public static var testValue: ModelContext {
    unimplemented("ModelContextProvider testValue", placeholder: ModelContextKey.testValue)
  }
}

/// Create a ModelContainer to be used in a live environment.
func makeLiveContainer(dbFile: URL) -> ModelContainer {
  do {
    let schema = Schema(versionedSchema: ActiveSchema.self)
    let config = ModelConfiguration(schema: schema, url: dbFile, cloudKitDatabase: .none)
    return try ModelContainer(for: schema, migrationPlan: MigrationPlan.self, configurations: config)
  } catch {
    fatalError("Failed to create live container.")
  }
}

private let liveContainer: ModelContainer = makeLiveContainer(
  dbFile: URL.applicationSupportDirectory.appending(path: "Modelv5.sqlite")
)

internal func makeTestContext(mockCount: Int = 0) throws -> ModelContext {
  try makeMockContext(mockCount: mockCount)
}

internal func makeMockContext(mockCount: Int) throws -> ModelContext {
  let context = ModelContext(makeInMemoryContainer())
  try Support.generateMocks(context: context, count: mockCount)
  return context
}

internal func makeInMemoryContainer() -> ModelContainer {
  do {
    let schema = Schema(versionedSchema: ActiveSchema.self)
    let config = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: true,
      groupContainer: .none,
      cloudKitDatabase: .none
    )
    return try ModelContainer(for: schema, migrationPlan: nil, configurations: config)
  } catch {
    fatalError("Failed to create in-memory container.")
  }
}

@MainActor private let liveContext: (() -> ModelContext) = { liveContainer.mainContext }

@MainActor private let previewContext: (() -> ModelContext) = {
  do {
    return try makeMockContext(mockCount: 32)
  } catch {
    fatalError("Failed to generate mocks in previw context")
  }
}

#if hasFeature(RetroactiveAttribute)
extension KeyPath: @unchecked @retroactive Sendable {}
extension ModelContext: @unchecked @retroactive Sendable {}
#else
extension KeyPath: @unchecked Sendable {}
extension ModelContext: @unchecked Sendable {}
#endif
