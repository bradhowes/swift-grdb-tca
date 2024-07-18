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

    /**
     Add `Actor` to the collection of actors in this movie.

     NOTE: make sure `Actor` and `Movie` have already been inserted into database before calling this method.

     - parameter actor: the `Actor` to add
     */
    func addActor(_ actor: _Actor) {
      guard !actors.contains(actor) else { return }
      actors.append(actor)
      actor.movies.append(self)
    }
  }

  static func makeMock(context: ModelContext) {
    @Dependency(\.uuid) var uuid
    let entry = Support.mockMovieEntry
    let movie = _Movie(id: uuid(), title: entry.0)
    context.insert(movie)

    for name in entry.1 {
      let actor = fetchOrMakeActor(context, name: name)
      movie.actors.append(actor)
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
}

extension SchemaV4._Movie: Sendable {}
extension SchemaV4._Actor: Sendable {}
