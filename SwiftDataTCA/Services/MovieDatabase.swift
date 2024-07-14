import Dependencies
import Foundation
import SwiftData

struct MovieDatabase {
  var fetchAll: @Sendable () throws -> [Movie]
  var fetch: @Sendable (FetchDescriptor<Movie>) throws -> [Movie]
  var add: @Sendable (Movie) -> Void
  var delete: @Sendable (Movie) -> Void

  enum MovieError: Error {
    case add
    case delete
  }
}

extension MovieDatabase: DependencyKey {
  static let liveValue = Self(
    fetchAll: {
      do {
        @Dependency(\.modelContextProvider.context) var modelContextProvider
        let movieContext = modelContextProvider()
        let descriptor = FetchDescriptor<Movie>(sortBy: [SortDescriptor(\.title)])
        return try movieContext.fetch(descriptor)
      } catch {
        return []
      }
    },
    fetch: { descriptor in
      do {
        @Dependency(\.modelContextProvider.context) var modelContextProvider
        let movieContext = modelContextProvider()
        return try movieContext.fetch(descriptor)
      } catch {
        return []
      }
    },
    add: { model in
      @Dependency(\.modelContextProvider.context) var modelContextProvider
      let movieContext = modelContextProvider()
      movieContext.insert(model)
      // try! movieContext.save()
    },
    delete: { model in
      @Dependency(\.modelContextProvider.context) var modelContextProvider
      let movieContext = modelContextProvider()
      let modelToBeDelete = model
      movieContext.delete(modelToBeDelete)
      // try! movieContext.save()
    }
  )
}

extension MovieDatabase: TestDependencyKey {
  public static let testValue = Self(
    fetchAll: unimplemented("\(Self.self).fetch"),
    fetch: unimplemented("\(Self.self).fetchDescriptor"),
    add: unimplemented("\(Self.self).add"),
    delete: unimplemented("\(Self.self).delete")
  )
}

extension DependencyValues {
  var movieDatabase: MovieDatabase {
    get { self[MovieDatabase.self] }
    set { self[MovieDatabase.self] = newValue }
  }
}
