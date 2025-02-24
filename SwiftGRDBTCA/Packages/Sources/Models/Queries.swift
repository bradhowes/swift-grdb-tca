import Foundation
import GRDB
import IdentifiedCollections
import SharedGRDB


public struct AllMoviesQuery: FetchKeyRequest {
  public let ordering: SortOrder?
  public let searchText: String?

  public init(ordering: SortOrder? = .forward, searchText: String? = nil) {
    self.ordering = ordering
    self.searchText = searchText
  }

  public func fetch(_ db: Database) throws -> MovieCollection {
    let rows = try Movie.all().order(ordering?.by(Movie.Columns.sortableTitle)).fetchAll(db)
    if let searchText, !searchText.isEmpty {
      return .init(
        uncheckedUniqueElements: rows.filter { $0.sortableTitle.localizedCaseInsensitiveContains(searchText) }
      )
    }
    return .init(uncheckedUniqueElements: rows)
  }
}

public struct AllActorsQuery: FetchKeyRequest {
  let ordering: SortOrder?

  public init(ordering: SortOrder? = .forward) {
    self.ordering = ordering
  }

  public func fetch(_ db: Database) throws -> ActorCollection {
    try Actor.all().order(ordering?.by(Actor.Columns.name)).fetchIdentifiedArray(db)
  }
}

public struct ActorMoviesQuery: FetchKeyRequest {
  let actor: Actor
  let ordering: SortOrder?

  public init(actor: Actor, ordering: SortOrder? = .forward) {
    self.actor = actor
    self.ordering = ordering
  }

  public func fetch(_ db: Database) throws -> MovieCollection {
    try actor.movies.order(ordering?.by(Movie.Columns.sortableTitle)).fetchIdentifiedArray(db)
  }
}

public struct MovieActorsQuery: FetchKeyRequest {
  let movie: Movie
  let ordering: SortOrder?

  public init(movie: Movie, ordering: SortOrder? = .forward) {
    self.movie = movie
    self.ordering = ordering
  }

  public func fetch(_ db: Database) throws -> ActorCollection {
    try movie.actors.order(ordering?.by(Actor.Columns.name)).fetchIdentifiedArray(db)
  }
}

public struct MovieQuery: FetchKeyRequest {
  let id: Movie.ID

  public init(id: Movie.ID) {
    self.id = id
  }

  public func fetch(_ db: Database) throws -> Movie? {
    try Movie.filter(id: id).fetchOne(db)
  }
}

extension FetchRequest where RowDecoder: FetchableRecord & Identifiable {
  public func fetchIdentifiedArray(_ db: Database) throws -> IdentifiedArrayOf<RowDecoder> {
    try IdentifiedArray(fetchCursor(db))
  }
}

extension DatabaseReader {

  public func movies(ordering: SortOrder? = .forward) -> MovieCollection {
    (try? read { try AllMoviesQuery(ordering: ordering).fetch($0) }) ?? []
  }

  public func movies(for actor: Actor, ordering: SortOrder? = .forward) -> MovieCollection {
    (try? read { try ActorMoviesQuery(actor: actor, ordering: ordering).fetch($0) }) ?? []
  }

  public func actors(ordering: SortOrder? = .forward) -> ActorCollection {
    (try? read { try AllActorsQuery(ordering: ordering).fetch($0) }) ?? []
  }

  public func actors(for movie: Movie, ordering: SortOrder? = .forward) -> ActorCollection {
    (try? read { try MovieActorsQuery(movie: movie, ordering: ordering).fetch($0) }) ?? []
  }

  public func movie(id: Movie.ID) -> Movie? {
    try? read { try MovieQuery(id: id).fetch($0) }
  }
}

public extension IdentifiedArray where Element == Actor {
  var csv: String { self.map(\.name).joined(separator: ", ") }
}

public extension IdentifiedArray where Element == Movie {
  var csv: String { self.map(\.title).joined(separator: ", ") }
}
