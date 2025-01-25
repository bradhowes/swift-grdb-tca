import Dependencies
import Foundation
import GRDB
import Models
import Sharing
import Testing


@Test func testDependencyKey() async throws {
  @Dependency(\.date) var date
  @Dependency(\.date.now) var now

  withDependencies {
    $0.date.now = Date(timeIntervalSinceReferenceDate: 0)
  } operation: {
    #expect( now == Date(timeIntervalSinceReferenceDate: 0))
    #expect( date() == Date(timeIntervalSinceReferenceDate: 0))
  }
}

@Test func testActorMoviesSharedReaderKey() async throws {
  try withDependencies {
    $0.defaultDatabase = try DatabaseQueue.appDatabase()
  } operation: {
    struct Foo {
      let actor: Actor
      var movieTitles: String { movies.map(\.title).joined(separator: ", ") }
      var ordering: SortOrder = .forward {
        didSet {
          _movies = SharedReader(.fetch(ActorMoviesQuery(actor: actor, ordering: ordering)))
        }
      }

      @SharedReader var movies: [Movie]
      init() throws {
        @Dependency(\.defaultDatabase) var db
        let actors = try db.read { try Actor.fetchAll($0) }
        let actor = actors[2]
        self.actor = actor
        _movies = SharedReader(.fetch(ActorMoviesQuery(actor: actor, ordering: ordering)))
      }
    }

    @Dependency(\.defaultDatabase) var queue
    try queue.write { try Support.generateMocks(db: $0, count: 13) }

    var foo = try Foo()
    print(foo.actor.name)
    #expect(foo.movies.count == 8)
    #expect(foo.movies[0].title == "Apocalypse Now")
    #expect(foo.movies[1].title == "Don Juan DeMarco")

    foo.ordering = .reverse
    #expect(foo.movies.count == 8)
    #expect(foo.movies[0].title == "Superman")
    #expect(foo.movies[1].title == "A Streetcar Named Desire")
    #expect(foo.movieTitles == "Superman, A Streetcar Named Desire, The Score, On the Waterfront, The Island of Dr. Moreau, The Godfather, Don Juan DeMarco, Apocalypse Now")
  }
}


@Test func testMovieActorsSharedReaderKey() async throws {
  try withDependencies {
    $0.defaultDatabase = try DatabaseQueue.appDatabase()
  } operation: {
    struct Foo {
      let movie: Movie
      var actorNames: String { actors.map(\.name).joined(separator: ", ") }
      var ordering: SortOrder = .forward {
        didSet {
          _actors = SharedReader(.fetch(MovieActorsQuery(movie: movie, ordering: ordering)))
        }
      }

      @SharedReader var actors: [Actor]
      init() throws {
        @Dependency(\.defaultDatabase) var db
        let movies = try db.read { try Movie.fetchAll($0) }
        let movie = movies[0]
        self.movie = movie
        _actors = SharedReader(.fetch(MovieActorsQuery(movie: movie, ordering: ordering)))
      }
    }

    @Dependency(\.defaultDatabase) var queue
    try queue.write { try Support.generateMocks(db: $0, count: 13) }

    var foo = try Foo()
    #expect(foo.movie.title == "The Score")
    #expect(foo.actors.count == 5)
    #expect(foo.actors[0].name == "Angela Bassett")
    #expect(foo.actors[1].name == "Edward Norton")
    #expect(foo.actorNames == "Angela Bassett, Edward Norton, Marlon Brando, Paul Soles, Robert De Niro")

    foo.ordering = .reverse
    #expect(foo.actorNames == "Robert De Niro, Paul Soles, Marlon Brando, Edward Norton, Angela Bassett")
  }
}
