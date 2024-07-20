import Foundation
import SwiftData

/// Schema v5 removes the UUID attributes from the models.
enum SchemaV5: VersionedSchema {
  static var versionIdentifier: Schema.Version { .init(5, 0, 0) }

  static var models: [any PersistentModel.Type] {
    [
      _Actor.self,
      _Movie.self
    ]
  }

  @Model
  final class _Actor {
    let name: String
    var movies: [_Movie]

    init(name: String) {
      self.name = name
      self.movies = []
    }
  }

  @Model
  final class _Movie {
    let title: String
    var favorite: Bool = false
    var sortableTitle: String = ""
    @Relationship(inverse: \_Actor.movies) var actors: [_Actor]

    init(title: String, favorite: Bool = false) {
      self.title = title
      self.favorite = favorite
      self.sortableTitle = Support.sortableTitle(title)
      self.actors = []
    }

    /**
     Add `Actor` to the collection of actors in this movie.

     NOTE: make sure `Actor` and `Movie` have already been inserted into database before calling this method.

     - parameter actor: the `Actor` to add
     */
    func addActor(_ actor: _Actor) {
      actors.append(actor)
      actor.movies.append(self)
    }
  }

  static func makeMock(context: ModelContext, entry: (title: String, cast: [String])) {
    let movie = _Movie(title: entry.0)
    context.insert(movie)

    let actors = entry.cast.map { fetchOrMakeActor(context, name: $0) }
    movie.actors = actors
    for actor in actors {
      actor.movies.append(movie)
    }
  }

  static func fetchOrMakeActor(_ context: ModelContext, name: String) -> _Actor {
    let predicate = #Predicate<_Actor> { $0.name == name }
    let fetchDescriptor = FetchDescriptor<_Actor>(predicate: predicate)
    if let actors = (try? context.fetch(fetchDescriptor)), !actors.isEmpty {
      return actors[0]
    }

    let actor = _Actor(name: name)
    context.insert(actor)

    return actor
  }

  static func movieFetchDescriptor(titleSort: SortOrder?, searchString: String) -> FetchDescriptor<_Movie> {
    let sortBy: [SortDescriptor<_Movie>] = [sortBy(\.sortableTitle, order: titleSort)].compactMap { $0 }
    let predicate: Predicate<_Movie> = #Predicate<_Movie> {
      searchString.isEmpty ? true : $0.title.localizedStandardContains(searchString)
    }

    var fetchDescriptor = FetchDescriptor(predicate: predicate, sortBy: sortBy)
    fetchDescriptor.relationshipKeyPathsForPrefetching = [\.actors]

    return fetchDescriptor
  }

  static func sortBy<Value: Comparable>(_ key: KeyPath<_Movie, Value>, order: SortOrder?) -> SortDescriptor<_Movie>? {
    guard let order else { return nil }
    return .init(key, order: order)
  }
}

extension SchemaV5._Movie: Sendable {}
extension SchemaV5._Actor: Sendable {}
