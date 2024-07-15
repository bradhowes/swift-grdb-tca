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
  final class Actor {
    let id: UUID
    let name: String
    var movies: [Movie] = []

    init(id: UUID, name: String) {
      self.id = id
      self.name = name
    }
  }

  @Model
  final class Movie {
    let id: UUID
    let title: String
    private let cast: [String] = []
    var favorite: Bool = false
    var sortableTitle: String = ""
    var actors: [Actor] = []

    init(id: UUID, title: String, favorite: Bool = false) {
      self.id = id
      self.title = title
      self.favorite = favorite
      self.sortableTitle = SchemaV3.Movie.sortableTitle(title)
    }
  }

  static var mock: Movie {
    @Dependency(\.withRandomNumberGenerator) var withRandomNumberGenerator
    @Dependency(\.uuid) var uuid
    let index = withRandomNumberGenerator { generator in
      Int.random(in: 0..<mockData.count, using: &generator)
    }
    let entry = mockData[index]
    let movie = Movie(id: uuid(), title: entry.0)


    return (movie, entry.1)
  }

  static func fetchActor(_ context: ModelContext, name: String) -> Actor? {
    let predicate = #Predicate<Actor> { $0.name.localizedStandardCompare(name) == .orderedSame }
    let fetchDescriptor = FetchDescriptor<Actor>(predicate: predicate)
    let actors = (try? context.fetch(fetchDescriptor)) ?? []
    return actors.first
  }

  static func populateCast(_ context: ModelContext, movie: Movie, cast: [String]) {
    context.insert(movie)
    try? context.save()
    for name in cast {
      if let actor = fetchActor(context, name: name) {
        movie.actors.append(actor)
      } else {

      }
    }
  }
}

extension SchemaV4.Movie: Sendable {}
extension SchemaV4.Actor: Sendable {}
