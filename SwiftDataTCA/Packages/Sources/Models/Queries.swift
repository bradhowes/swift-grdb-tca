import Foundation
import GRDB
import IdentifiedCollections
import SharedGRDB


public struct AllMoviesQuery: FetchKeyRequest {
  public let ordering: SortOrder?

  public init(ordering: SortOrder? = .forward) {
    self.ordering = ordering
  }

  public func fetch(_ db: Database) throws -> IdentifiedArrayOf<Movie> {
    try .init(uncheckedUniqueElements: Movie.all().order(ordering?.by(Movie.Columns.sortableTitle)).fetchAll(db))
  }
}

public struct AllActorsQuery: FetchKeyRequest {
  let ordering: SortOrder?

  public init(ordering: SortOrder? = .forward) {
    self.ordering = ordering
  }

  public func fetch(_ db: Database) throws -> IdentifiedArrayOf<Actor> {
    try .init(uncheckedUniqueElements: Actor.all().order(ordering?.by(Actor.Columns.name)).fetchAll(db))
  }
}

public struct ActorMoviesQuery: FetchKeyRequest {
  let actor: Actor
  let ordering: SortOrder?

  public init(actor: Actor, ordering: SortOrder? = .forward) {
    self.actor = actor
    self.ordering = ordering
  }

  public func fetch(_ db: Database) throws -> IdentifiedArrayOf<Movie> {
    try .init(uncheckedUniqueElements: actor.movies.order(ordering?.by(Movie.Columns.sortableTitle)).fetchAll(db))
  }
}

public struct MovieActorsQuery: FetchKeyRequest {
  let movie: Movie
  let ordering: SortOrder?

  public init(movie: Movie, ordering: SortOrder? = .forward) {
    self.movie = movie
    self.ordering = ordering
  }

  public func fetch(_ db: Database) throws -> IdentifiedArrayOf<Actor> {
    try .init(uncheckedUniqueElements: movie.actors.order(ordering?.by(Actor.Columns.name)).fetchAll(db))
  }
}

extension DatabaseReader {

  public func actors(ordering: SortOrder? = .forward) -> IdentifiedArrayOf<Actor> {
    (try? read { try AllActorsQuery(ordering: ordering).fetch($0) }) ?? []
  }

  public func movies(ordering: SortOrder? = .forward) -> IdentifiedArrayOf<Movie> {
    (try? read { try AllMoviesQuery(ordering: ordering).fetch($0) }) ?? []
  }

  public func moviesFor(actor: Actor, ordering: SortOrder? = .forward) -> IdentifiedArrayOf<Movie> {
    (try? read { try ActorMoviesQuery(actor: actor, ordering: ordering).fetch($0) }) ?? []
  }

  public func actorsFor(movie: Movie, ordering: SortOrder? = .forward) -> IdentifiedArrayOf<Actor> {
    (try? read { try MovieActorsQuery(movie: movie, ordering: ordering).fetch($0) }) ?? []
  }
}


