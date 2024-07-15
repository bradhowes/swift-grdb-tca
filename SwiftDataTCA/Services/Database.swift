import Dependencies
import Foundation
import SwiftData

struct Database {
  var fetchMovies: @Sendable (FetchDescriptor<Movie>) -> [Movie]
  var fetchActors: @Sendable (FetchDescriptor<Actor>) -> [Actor]
  var add: @Sendable (Movie, [Actor]) -> Void
  var delete: @Sendable (Movie) -> Void
  var save: @Sendable () -> Void

  enum MovieError: Error {
    case add
    case delete
  }
}

extension Database: DependencyKey {
  static let liveValue = Self(
    fetchMovies: { descriptor in
      @Dependency(\.modelContextProvider.context) var modelContextProvider
      let context = modelContextProvider()
      return (try? context.fetch(descriptor)) ?? []
    },
    fetchActors: { descriptor in
      @Dependency(\.modelContextProvider.context) var modelContextProvider
      let context = modelContextProvider()
      return (try? context.fetch(descriptor)) ?? []
    },
    add: { movie, actors in
      @Dependency(\.modelContextProvider.context) var modelContextProvider
      let context = modelContextProvider()
      movieContext.insert(movie)

    },
    delete: { model in
      @Dependency(\.modelContextProvider.context) var modelContextProvider
      let movieContext = modelContextProvider()
      movieContext.delete(model)
    },
    save: {
      @Dependency(\.modelContextProvider.context) var modelContextProvider
      let movieContext = modelContextProvider()
      try? movieContext.save()
    }
  )
}

extension Database: TestDependencyKey {
  public static let testValue = Self(
    fetch: unimplemented("\(Self.self).fetchDescriptor"),
    add: unimplemented("\(Self.self).add"),
    delete: unimplemented("\(Self.self).delete"),
    save: unimplemented("\(Self.self).save")
  )
}

extension DependencyValues {
  var movieDatabase: Database {
    get { self[Database.self] }
    set { self[Database.self] = newValue }
  }
}
