import Foundation
import GRDB
import SharedGRDB

public struct AllMoviesQuery: FetchKeyRequest {
  public let ordering: SortOrder?

  public init(ordering: SortOrder? = .forward) {
    self.ordering = ordering
  }

  public func fetch(_ db: Database) throws -> [Movie] {
    try Movie.all().order(ordering?.by(Movie.Columns.sortableTitle)).fetchAll(db)
  }
}

public struct AllActorsQuery: FetchKeyRequest {
  let ordering: SortOrder?

  public init(ordering: SortOrder? = .forward) {
    self.ordering = ordering
  }

  public func fetch(_ db: Database) throws -> [Actor] {
    try Actor.all().order(ordering?.by(Actor.Columns.name)).fetchAll(db)
  }
}

public struct ActorMoviesQuery: FetchKeyRequest {
  let actor: Actor
  let ordering: SortOrder?

  public init(actor: Actor, ordering: SortOrder? = .forward) {
    self.actor = actor
    self.ordering = ordering
  }

  public func fetch(_ db: Database) throws -> [Movie] {
    try actor.movies.order(ordering?.by(Movie.Columns.title)).fetchAll(db)
  }
}

public struct MovieActorsQuery: FetchKeyRequest {
  let movie: Movie
  let ordering: SortOrder?

  public init(movie: Movie, ordering: SortOrder? = .forward) {
    self.movie = movie
    self.ordering = ordering
  }

  public func fetch(_ db: Database) throws -> [Actor] {
    try movie.actors.order(ordering?.by(Actor.Columns.name)).fetchAll(db)
  }
}

