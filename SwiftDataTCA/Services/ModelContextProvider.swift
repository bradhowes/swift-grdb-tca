import Foundation
import Dependencies
import SwiftData


typealias ActiveSchema = SchemaV3
typealias Movie = ActiveSchema.Movie

extension DependencyValues {
  var modelContextProvider: ModelContextProvider {
    get { self[ModelContextProvider.self] }
    set { self[ModelContextProvider.self] = newValue }
  }
}

fileprivate let liveContext: ModelContext = { ModelContext(liveContainer) }()
fileprivate let previewContext: ModelContext = { ModelContext(previewContainer) }()

fileprivate let liveContainer: ModelContainer = {
  do {
    let url = URL.applicationSupportDirectory.appending(path: "Modelv3.sqlite")
    let config = ModelConfiguration(schema: ActiveSchema.schema, url: url)
    return try ModelContainer(for: Movie.self, migrationPlan: MigrationPlan.self, configurations: config)
  } catch {
    fatalError("Failed to create live container.")
  }
}()

fileprivate let previewContainer: ModelContainer = {
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
    context: { liveContext },
    container: { liveContainer }
  )
}

extension ModelContextProvider: TestDependencyKey {
  public static var previewValue: ModelContextProvider { Self.inMemory }
  public static var testValue: ModelContextProvider { Self.inMemory }
  private static let inMemory = Self(
    context: { previewContext },
    container: { previewContainer }
  )
}

extension ActiveSchema.Movie {
  static var mock: Movie {
    @Dependency(\.withRandomNumberGenerator) var withRandomNumberGenerator
    @Dependency(\.uuid) var uuid
    let index = withRandomNumberGenerator { generator in
      Int.random(in: 0..<mockData.count, using: &generator)
    }
    let entry = mockData[index]
    return Movie(id: uuid(), title: entry.0, cast: entry.1)
  }
}

extension VersionedSchema {
  static var schema: Schema { Schema(versionedSchema: Self.self) }
}

extension KeyPath: @unchecked @retroactive Sendable {}
extension ModelContext: @unchecked @retroactive Sendable {}
