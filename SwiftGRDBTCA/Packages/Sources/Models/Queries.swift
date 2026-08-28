import Foundation
import SQLiteData

public struct AllMoviesQuery: FetchKeyRequest {
  public let ordering: SortOrder?
  public let searchText: String?
  
  public init(ordering: SortOrder? = .forward, searchText: String? = nil) {
    self.ordering = ordering
    self.searchText = searchText
  }

  public func fetch(_ db: Database) throws -> MovieCollection {
    let found: [Movie]
    if let searchText, !searchText.isEmpty {
      found = try MovieText.where {
        $0.match(searchText + "*")
      }
      .join(Movie.all) { $0.rowid.eq($1.rowid) }
      .order {
        if ordering == .forward {
          $1.sortableTitle
        } else if ordering == .reverse {
          $1.sortableTitle.desc()
        }
      }
      .select {
        $1
      }
      .fetchAll(db)
    } else {
      found = try Movie.all
        .order {
          if ordering == .forward {
            $0.sortableTitle
          } else if ordering == .reverse {
            $0.sortableTitle.desc()
          }
        }
        .fetchAll(db)
    }

    return .init(uniqueElements: found)
  }
}

//  select title, sortableTitle, favorite, group_concat(name, ', ' order by name)
//  from (
//    select movies.title, movies.sortableTitle, movies.favorite, actors.name
//    from movies
//    join movieActors on movies.id = movieActors.moviesId
//    join actors on actors.id = movieActors.actorsId
//  )
//  group by title;

public struct ActorMoviesQuery: FetchKeyRequest {
  let actor: Actor
  let ordering: SortOrder?
  let searchText: String?

  public init(actor: Actor, ordering: SortOrder? = .forward, searchText: String? = nil) {
    self.actor = actor
    self.ordering = ordering
    self.searchText = searchText
  }

  public func fetch(_ db: Database) throws -> MovieCollection {
    let found: [Movie]
    if let searchText, !searchText.isEmpty {
      let movieIds = try MovieActor
        .where { $0.actorId.eq(actor.id) }
        .select(\.movieId)
        .fetchAll(db)
      guard !movieIds.isEmpty else { return [] }

      found = try MovieText.where {
        $0.match(searchText + "*")
      }
      .join(Movie.all) { $0.movieId.eq($1.id) }
      .where { $1.id.in(movieIds) }
      .order {
        if ordering == .forward {
          $1.sortableTitle
        } else if ordering == .reverse {
          $1.sortableTitle.desc()
        }
      }
      .select {
        $1
      }
      .fetchAll(db)
    } else {
      found = try MovieActor
        .where { $0.actorId.eq(actor.id) }
        .join(Movie.all) { $0.movieId.eq($1.id) }
        .order { _, movie in
          if ordering == .forward {
            movie.sortableTitle
          } else if ordering == .reverse {
            movie.sortableTitle.desc()
          }
        }
        .select { _, movie in
          movie
        }
        .fetchAll(db)
    }

    return .init(uniqueElements: found)
  }
}

public struct MovieActorsQuery: FetchKeyRequest {
  let movie: Movie
  let ordering: SortOrder?
  let searchText: String?

  public init(movie: Movie, ordering: SortOrder? = .forward, searchText: String? = nil) {
    self.movie = movie
    self.ordering = ordering
    self.searchText = searchText
  }

  public func fetch(_ db: Database) throws -> ActorCollection {
    let found: [Actor]
    if let searchText, !searchText.isEmpty {
      let actorIds = try MovieActor
        .where { $0.movieId.eq(movie.id) }
        .select(\.actorId)
        .fetchAll(db)
      guard !actorIds.isEmpty else { return [] }

      found = try ActorText.where {
        $0.match(searchText + "*")
      }
      .join(Actor.all) { $0.actorId.eq($1.id) }
      .where { $1.id.in(actorIds) }
      .order {
        if ordering == .forward {
          $1.name
        } else if ordering == .reverse {
          $1.name.desc()
        }
      }
      .select { $1 }
      .fetchAll(db)
    } else {
      found = try MovieActor
        .where { $0.movieId.eq(movie.id) }
        .join(Actor.all) { $0.actorId.eq($1.id) }
        .order { _, actor in
          if ordering == .forward {
            actor.name
          } else if ordering == .reverse {
            actor.name.desc()
          }
        }
        .select { _, actor in
          actor
        }
        .fetchAll(db)
    }
    return .init(uniqueElements: found)
  }
}
