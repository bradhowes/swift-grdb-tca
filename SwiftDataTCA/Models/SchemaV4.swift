import Dependencies
import Foundation
import SwiftData

/// Schema v4 has a new `_Actor` model that holds the unique name of an actor. It also establishes a many-to-many
/// relationship between `_Movie` entities and `_Actor` entities.
enum SchemaV4: VersionedSchema {
  static var versionIdentifier: Schema.Version { .init(4, 0, 0) }

  static var models: [any PersistentModel.Type] {
    [
      _Actor.self,
      _Movie.self
    ]
  }

  @Model
  final class _Actor {
    let id: UUID
    let name: String
    var movies: [_Movie]

    init(id: UUID, name: String) {
      self.id = id
      self.name = name
      self.movies = []
    }
  }

  @Model
  final class _Movie {
    let id: UUID
    let title: String
    var favorite: Bool = false
    var sortableTitle: String = ""
    @Relationship(inverse: \_Actor.movies) var actors: [_Actor]

    init(id: UUID, title: String, favorite: Bool = false) {
      self.id = id
      self.title = title
      self.favorite = favorite
      self.sortableTitle = Support.sortableTitle(title)
      self.actors = []
    }

    func addActor(_ actor: _Actor) {
      actors.append(actor)
      actor.movies.append(self)
    }
  }
}

extension SchemaV4 {

  static func makeMock(context: ModelContext, entry: (title: String, cast: [String])) {
    @Dependency(\.uuid) var uuid
    let movie = _Movie(id: uuid(), title: entry.title)
    context.insert(movie)

    let actors = entry.cast.map { fetchOrMakeActor(context, name: $0) }
    movie.actors = actors
    for actor in actors {
      actor.movies.append(movie)
    }
  }

  static func fetchOrMakeActor(_ context: ModelContext, name: String) -> _Actor {
    @Dependency(\.uuid) var uuid
    let predicate = #Predicate<_Actor> { $0.name == name }
    let fetchDescriptor = FetchDescriptor<_Actor>(predicate: predicate)
    if let actors = (try? context.fetch(fetchDescriptor)), !actors.isEmpty {
      return actors[0]
    }

    let actor = _Actor(id: uuid(), name: name)
    context.insert(actor)

    return actor
  }

  /**
   Obtain a `FetchDescriptor` that will return an ordered and possibly filtered set of known `_Movie` entities.
   Ordering is done on the `_Movie.sortableTitle` attribute.

   - parameter titleSort: the direction of the ordering -- alphabetical or reveresed alphabetical
   - parameter searchString: if not empty, only return `_Movie` entities whose `title` contains the search string
   - returns: new `FetchDescriptor`
   */
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

extension SchemaV4._Movie: Sendable {}
extension SchemaV4._Actor: Sendable {}
