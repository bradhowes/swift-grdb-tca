import Dependencies
import Foundation
import SwiftData

typealias ActiveSchema = SchemaV4
typealias Actor = ActiveSchema._Actor
typealias Movie = ActiveSchema._Movie

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
  var modelContextProvider: ModelContextProvider {
    get { self[ModelContextProvider.self] }
    set { self[ModelContextProvider.self] = newValue }
  }
}

extension ModelContextProvider: DependencyKey {
  public static let liveValue = Self(context: liveContext())
}

extension ModelContextProvider: TestDependencyKey {
  public static var previewValue: ModelContextProvider {
    let context = previewContext()
    loadPreview(context)
    return .init(context: context)
  }
  public static var testValue: ModelContextProvider { .init(context: testContext()) }
}

/// Create a ModelContainer to be used in a live environment.
private let liveContainer: ModelContainer = {
  do {
    let schema = Schema(versionedSchema: ActiveSchema.self)
    let url = URL.applicationSupportDirectory.appending(path: "Modelv5.sqlite")
    let config = ModelConfiguration(schema: schema, url: url)
    return try ModelContainer(for: schema, migrationPlan: MigrationPlan.self, configurations: config)
  } catch {
    fatalError("Failed to create live container.")
  }
}()

/// Create a ModelContainer to be used in test and preview environments.
private let inMemoryContainer: ModelContainer = {
  do {
    let schema = Schema(versionedSchema: ActiveSchema.self)
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, allowsSave: true)
    return try ModelContainer(for: schema, migrationPlan: nil, configurations: config)
  } catch {
    fatalError("Failed to create in-memory container.")
  }
}()

@MainActor private let liveContext: (() -> ModelContext) = { liveContainer.mainContext }
@MainActor private let previewContext: (() -> ModelContext) = { inMemoryContainer.mainContext }
@MainActor private let testContext: (() -> ModelContext) = { ModelContext(inMemoryContainer) }

private func loadPreview(_ context: ModelContext) {
  @Dependency(\.uuid) var uuid
  SchemaV4.makeMock(context: context, entry: Support.mockMovieEntry)
}

#if hasFeature(RetroactiveAttribute)
extension KeyPath: @unchecked @retroactive Sendable {}
extension ModelContext: @unchecked @retroactive Sendable {}
#else
extension KeyPath: @unchecked Sendable {}
extension ModelContext: @unchecked Sendable {}
#endif
