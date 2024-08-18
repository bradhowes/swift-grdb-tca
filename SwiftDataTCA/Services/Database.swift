import Dependencies
import Foundation
import SwiftData

/**
 Collection of SwiftData operations one can perform on a "database" regardless of operating environment.
 */
struct Database {
  var fetchMovies: @Sendable (FetchDescriptor<MovieModel>) -> [MovieModel]
  var resolveMovie: @Sendable (PersistentIdentifier) -> MovieModel
  var resolveActor: @Sendable (PersistentIdentifier) -> ActorModel
  var add: @Sendable () -> Void
  var delete: @Sendable (MovieModel) -> Void
  var save: @Sendable () -> Void
}

@Sendable
private func doFetchMovies(_ descriptor: FetchDescriptor<MovieModel>) -> [MovieModel] {
  @Dependency(\.modelContextProvider.context) var context
  return (try? context.fetch(descriptor)) ?? []
}

@Sendable
private func doAdd() {
  @Dependency(\.modelContextProvider.context) var context
  ActiveSchema.makeMock(
    context: context,
    entry: Support.nextMockMovieEntry(
      context: context,
      descriptor: ActiveSchema.movieFetchDescriptor(titleSort: .none, searchString: "")
    )
  )
}

@Sendable
private func doDelete(_ model: MovieModel) {
  @Dependency(\.modelContextProvider.context) var context
  context.delete(model)
}

@Sendable
private func doSave() {
  @Dependency(\.modelContextProvider.context) var context
  try? context.save()
}

@Sendable
private func doResolveMovie(_ modelId: PersistentIdentifier) -> MovieModel {
  @Dependency(\.modelContextProvider.context) var context
  // swiftlint:disable force_cast
  return context.model(for: modelId) as! MovieModel
  // swiftlint:enable force_cast
}

@Sendable
private func doResolveActor(_ modelId: PersistentIdentifier) -> ActorModel {
  @Dependency(\.modelContextProvider.context) var context
  // swiftlint:disable force_cast
  return context.model(for: modelId) as! ActorModel
  // swiftlint:enable force_cast
}

extension DependencyValues {
  var database: Database {
    get { self[Database.self] }
    set { self[Database.self] = newValue }
  }
}

extension Database: DependencyKey {
  static let liveValue = Self(
    fetchMovies: doFetchMovies,
    resolveMovie: doResolveMovie,
    resolveActor: doResolveActor,
    add: doAdd,
    delete: doDelete,
    save: doSave
  )
}

// The test version is the same -- the differences are found in the underlying `ModelContainer`, so there is no need
// right now to differentiate.
extension Database: TestDependencyKey {
  static let testValue = Self(
    fetchMovies: doFetchMovies,
    resolveMovie: doResolveMovie,
    resolveActor: doResolveActor,
    add: doAdd,
    delete: doDelete,
    save: doSave
  )
}
