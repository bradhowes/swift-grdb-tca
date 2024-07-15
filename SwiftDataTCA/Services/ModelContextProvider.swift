import Dependencies
import Foundation
import SwiftData

typealias ActiveSchema = SchemaV4
typealias Actor = ActiveSchema._Actor
typealias Movie = ActiveSchema._Movie

extension DependencyValues {
  var modelContextProvider: ModelContextProvider {
    get { self[ModelContextProvider.self] }
    set { self[ModelContextProvider.self] = newValue }
  }
}

@MainActor private let liveContext: (() -> ModelContext) = { liveContainer.mainContext }
@MainActor private let previewContext: (() -> ModelContext) = { previewContainer.mainContext }

private let liveContainer: ModelContainer = {
  do {
    let url = URL.applicationSupportDirectory.appending(path: "Modelv4.sqlite")
    let config = ModelConfiguration(schema: ActiveSchema.schema, url: url)
    return try ModelContainer(for: Movie.self, migrationPlan: MigrationPlan.self, configurations: config)
  } catch {
    fatalError("Failed to create live container.")
  }
}()

private let previewContainer: ModelContainer = {
  do {
    let config = ModelConfiguration(schema: ActiveSchema.schema, isStoredInMemoryOnly: true, allowsSave: true)
    return try ModelContainer(for: Movie.self, migrationPlan: MigrationPlan.self, configurations: config)
  } catch {
    fatalError("Failed to create preview container.")
  }
}()

struct ModelContextProvider {
  var context: @Sendable () -> ModelContext
  var container: @Sendable () -> ModelContainer
}

extension ModelContextProvider: DependencyKey {
  public static let liveValue = Self(
    context: { liveContext() },
    container: { liveContainer }
  )
}

extension ModelContextProvider: TestDependencyKey {
  public static var previewValue: ModelContextProvider { Self.inMemory }
  public static var testValue: ModelContextProvider { Self.inMemory }
  private static let inMemory = Self(
    context: { previewContext() },
    container: { previewContainer }
  )
}

extension VersionedSchema {
  static var schema: Schema { Schema(versionedSchema: Self.self) }
}

#if hasFeature(RetroactiveAttribute)
extension KeyPath: @unchecked @retroactive Sendable {}
extension ModelContext: @unchecked @retroactive Sendable {}
#else
extension KeyPath: @unchecked Sendable {}
extension ModelContext: @unchecked Sendable {}
#endif
