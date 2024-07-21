import Dependencies
import Foundation
import SwiftData

/**
 Collection of SwiftData operations one can perform on a "database" regardless of operating environment.
 */
struct Database {
  var fetchMovies: @Sendable (FetchDescriptor<Movie>) -> [Movie]
  var fetchActors: @Sendable (FetchDescriptor<Actor>) -> [Actor]
  var add: @Sendable () -> Void
  var delete: @Sendable (Movie) -> Void
  var save: @Sendable () -> Void
}

extension DependencyValues {
  var database: Database {
    get { self[Database.self] }
    set { self[Database.self] = newValue }
  }
}

extension Database: DependencyKey {
  static let liveValue = Self(
    fetchMovies: { descriptor in
      @Dependency(\.modelContextProvider.context) var context
      return (try? context.fetch(descriptor)) ?? []
    },
    fetchActors: { descriptor in
      @Dependency(\.modelContextProvider.context) var context
      return (try? context.fetch(descriptor)) ?? []
    },
    add: {
      @Dependency(\.modelContextProvider.context) var context
      SchemaV4.makeMock(context: context, entry: Support.mockMovieEntry)
    },
    delete: { model in
      @Dependency(\.modelContextProvider.context) var context
      context.delete(model)
    },
    save: {
      @Dependency(\.modelContextProvider.context) var context
      try? context.save()
    }
  )
}

/// Default all operations to 'unimplemented' -- a test must define the operations required to do its task.
extension Database: TestDependencyKey {
  static let testValue = Self(
    fetchMovies: { descriptor in
      @Dependency(\.modelContextProvider.context) var context
      return (try? context.fetch(descriptor)) ?? []
    },
    fetchActors: unimplemented("\(Self.self).fetchActors"),
    add: unimplemented("\(Self.self).add"),
    delete: unimplemented("\(Self.self).delete"),
    save: unimplemented("\(Self.self).save")
  )
}
