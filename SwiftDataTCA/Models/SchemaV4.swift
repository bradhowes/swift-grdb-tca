import Dependencies
import Foundation
import SwiftData

enum SchemaV4: VersionedSchema {
  static var versionIdentifier: Schema.Version { .init(4, 0, 0) }

  static var models: [any PersistentModel.Type] {
    [
      Actor.self,
      Movie.self
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
      self.actors.append(actor)
      actor.movies.append(self)
    }
  }

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

  static func movieFetchDescriptor(titleSort: SortOrder?, searchString: String) -> FetchDescriptor<_Movie> {
    let sortBy: [SortDescriptor<Movie>] = [sortBy(\.sortableTitle, order: titleSort)].compactMap { $0 }
    let predicate: Predicate<Movie> = #Predicate<Movie> {
      searchString.isEmpty ? true : $0.title.localizedStandardContains(searchString)
    }

    var fetchDescriptor = FetchDescriptor(predicate: predicate, sortBy: sortBy)

    // Fetch related actors since we show their names in movie listings
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
