import Dependencies
import Foundation
import SwiftData

struct MovieDatabase {
  var fetch: @Sendable (FetchDescriptor<Movie>) -> [Movie]
  var add: @Sendable (Movie) -> Void
  var delete: @Sendable (Movie) -> Void
  var save: @Sendable () -> Void

  enum MovieError: Error {
    case add
    case delete
  }
}

extension MovieDatabase: DependencyKey {
  static let liveValue = Self(
    fetch: { descriptor in
      @Dependency(\.modelContextProvider.context) var modelContextProvider
      let movieContext = modelContextProvider()
      return (try? movieContext.fetch(descriptor)) ?? []
    },
    add: { model in
      @Dependency(\.modelContextProvider.context) var modelContextProvider
      let movieContext = modelContextProvider()
      movieContext.insert(model)
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

extension MovieDatabase: TestDependencyKey {
  public static let testValue = Self(
    fetch: unimplemented("\(Self.self).fetchDescriptor"),
    add: unimplemented("\(Self.self).add"),
    delete: unimplemented("\(Self.self).delete"),
    save: unimplemented("\(Self.self).save")
  )
}

extension DependencyValues {
  var movieDatabase: MovieDatabase {
    get { self[MovieDatabase.self] }
    set { self[MovieDatabase.self] = newValue }
  }
}
