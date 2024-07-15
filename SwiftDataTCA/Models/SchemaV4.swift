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
    var movies: [_Movie] = []

    init(id: UUID, name: String) {
      self.id = id
      self.name = name
    }
  }

  @Model
  final class _Movie {
    let id: UUID
    let title: String
    let cast: [String] = []
    var favorite: Bool = false
    var sortableTitle: String = ""
    var actors: [_Actor] = []

    init(id: UUID, title: String, favorite: Bool = false) {
      self.id = id
      self.title = title
      self.favorite = favorite
      self.sortableTitle = SchemaV3._Movie.sortableTitle(title)
    }
  }

  static func makeMock(context: ModelContext) {
    @Dependency(\.withRandomNumberGenerator) var withRandomNumberGenerator
    @Dependency(\.uuid) var uuid
    let index = withRandomNumberGenerator { generator in
      Int.random(in: 0..<mockData.count, using: &generator)
    }
    let entry = mockData[index]
    let movie = _Movie(id: uuid(), title: entry.0)

    for name in entry.1 {
      let actor = fetchOrMakeActor(context, name: name)
      movie.actors.append(actor)
      actor.movies.append(movie)
    }

    context.insert(movie)
    try? context.save()
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
    try? context.save()

    return actor
  }
}

extension SchemaV4._Movie: Sendable {}
extension SchemaV4._Actor: Sendable {}
