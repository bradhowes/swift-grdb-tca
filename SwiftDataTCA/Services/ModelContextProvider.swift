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
    let schema = Schema(versionedSchema: ActiveSchema.self)
    let url = URL.applicationSupportDirectory.appending(path: "Modelv5.sqlite")
    let config = ModelConfiguration(schema: schema, url: url)
    return try ModelContainer(for: schema, migrationPlan: MigrationPlan.self, configurations: config)
  } catch {
    fatalError("Failed to create live container.")
  }
}()

private func loadPreview(_ context: ModelContext) {
  @Dependency(\.uuid) var uuid
  let movie = Movie(id: uuid(), title: mockData[0].0)
  let actors = mockData[0].1.map { Actor(id: uuid(), name: $0) }
  context.insert(movie)
  for actor in actors {
    context.insert(actor)
    movie.addActor(actor)
  }
}

private let previewContainer: ModelContainer = {
  do {
    let schema = Schema(versionedSchema: ActiveSchema.self)
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, allowsSave: true)
    let container = try ModelContainer(for: schema, migrationPlan: nil, configurations: config)
    let context = ModelContext(container)
    loadPreview(context)
    return container
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
