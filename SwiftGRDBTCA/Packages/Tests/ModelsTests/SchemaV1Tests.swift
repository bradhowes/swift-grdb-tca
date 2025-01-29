import Dependencies
import Foundation
import GRDB
import Testing
@testable import Models


@Test func testMigration() async throws {
  let db = try DatabaseQueue.appDatabase()
  try await db.read {
    try $0.execute(sql: "select * from movies")
    try $0.execute(sql: "select * from actors")
    try $0.execute(sql: "select * from movieactors")
  }
}

@Test func testMovieTable() async throws {
  let db = try DatabaseQueue.appDatabase()
  try await db.write { _ = try PendingMovie(title: "The Blob").insert($0) }
  let movies = try await db.read { try Movie.all().fetchAll($0) }
  #expect(movies.count == 1)
  #expect(movies[0].title == "The Blob")
  #expect(movies[0].sortableTitle == "blob")
  await #expect(throws: Error.self) { try await db.write { _ = try PendingMovie(title: "The Blob").insert($0) } }
}

@Test(
  "Movies FetchKeyRequest Honors Ordering",
  arguments: [
    (SortOrder.forward, ["Apocalpyse Now", "Basic Instinct", "The Godfather", "Wall Street"]),
    (SortOrder.reverse, ["Wall Street", "The Godfather", "Basic Instinct", "Apocalpyse Now"]),
    (nil, ["The Godfather", "Wall Street", "Basic Instinct", "Apocalpyse Now"])
  ]
)
func testMoviesFetchKeyRequest(args: (SortOrder?, [String])) async throws {
  let queue = try DatabaseQueue.appDatabase()
  try await queue.write { db in
    for title in ["The Godfather", "Wall Street", "Basic Instinct", "Apocalpyse Now"] {
      _ = try PendingMovie(title: title).insert(db)
    }
  }

  let movies = try await queue.read { db in try AllMoviesQuery(ordering: args.0).fetch(db) }
  print("expecting: \(args.1)")
  print("got: \(movies)")
  #expect(movies.count == args.1.count)
  #expect(movies.map(\.title) == args.1)
}

@Test func testActorTable() async throws {
  let db = try DatabaseQueue.appDatabase()
  try await db.write { _ = try PendingActor(name: "Marlon Brando").insert($0) }
  let actors = try await db.read { try Actor.all().fetchAll($0) }
  #expect(actors.count == 1)
  #expect(actors[0].name == "Marlon Brando")
  await #expect(throws: Error.self) { try await db.write { _ = try PendingActor(name: "Marlon Brando").insert($0) } }

  let bp1 = try await db.write { try Actor.fetchOrCreate(in: $0, name: "Brad Pitt") }
  let bp2 = try await db.write { try Actor.fetchOrCreate(in: $0, name: "Brad Pitt") }
  #expect(bp1 == bp2)
}

@Test(
  "Actor FetchKeyRequest Honors Ordering",
  arguments: [
    (SortOrder.forward, ["Al Pacino", "Diane Keaton", "Marlon Brando", "Martin Sheen", "Michael Douglas", "Sharon Stone"]),
    (SortOrder.reverse, ["Sharon Stone", "Michael Douglas", "Martin Sheen", "Marlon Brando", "Diane Keaton", "Al Pacino"]),
    (nil, ["Marlon Brando", "Martin Sheen", "Michael Douglas", "Sharon Stone", "Diane Keaton", "Al Pacino"])
  ]
)
func testActorFetchKeyRequest(args: (SortOrder?, [String])) async throws {
  let queue = try DatabaseQueue.appDatabase()
  try await queue.write { db in
    for name in ["Marlon Brando", "Martin Sheen", "Michael Douglas", "Sharon Stone", "Diane Keaton", "Al Pacino"] {
      _ = try PendingActor(name: name).insert(db)
    }
  }

  let actors = try await queue.read { db in try AllActorsQuery(ordering: args.0).fetch(db) }
  #expect(actors.count == args.1.count)
  #expect(actors.map(\.name) == args.1)
}

@Test("Movie Actor Relations")
func testMovieActorTable() async throws {
  let queue = try DatabaseQueue.appDatabase()

  try await queue.write { db in
    for title in ["Apocalypse Now", "Basic Instinct", "The Godfather", "Wall Street"] {
      _ = try PendingMovie(title: title).insert(db)
    }
  }

  let movies = try await queue.read { db in try AllMoviesQuery(ordering: .forward).fetch(db) }

  try await queue.write { db in
    for name in ["Al Pacino", "Diane Keaton", "Marlon Brando", "Martin Sheen", "Michael Douglas", "Sharon Stone"] {
      _ = try PendingActor(name: name).insert(db)
    }
  }

  let actors = try await queue.read { db in try AllActorsQuery(ordering: .forward).fetch(db) }

  try await queue.write { db in
    try MovieActor(moviesId: movies[0].id, actorsId: actors[2].id).insert(db)
    try MovieActor(moviesId: movies[0].id, actorsId: actors[3].id).insert(db)
    try MovieActor(moviesId: movies[1].id, actorsId: actors[4].id).insert(db)
    try MovieActor(moviesId: movies[1].id, actorsId: actors[5].id).insert(db)
    try MovieActor(moviesId: movies[2].id, actorsId: actors[0].id).insert(db)
    try MovieActor(moviesId: movies[2].id, actorsId: actors[1].id).insert(db)
    try MovieActor(moviesId: movies[2].id, actorsId: actors[2].id).insert(db)
    try MovieActor(moviesId: movies[3].id, actorsId: actors[3].id).insert(db)
    try MovieActor(moviesId: movies[3].id, actorsId: actors[4].id).insert(db)
  }

  let castSize = [2, 2, 3, 2]
  for (index, movie) in movies.enumerated() {
    #expect(try await queue.read { try movie.actors.fetchCount($0) } == castSize[index])
  }

  let appearances = [1, 1, 2, 2, 2, 1]
  for (index, actor) in actors.enumerated() {
    #expect(try await queue.read { try actor.movies.fetchCount($0) } == appearances[index])
  }

  _ = try await queue.write { try movies[0].delete($0) }

  let adjustedAppearances = [1, 1, 1, 1, 2, 1]
  for (index, actor) in actors.enumerated() {
    #expect(try await queue.read { try actor.movies.fetchCount($0) } == adjustedAppearances[index])
  }
}

@Test func testFavoriteToggle() async throws {
  let queue = try DatabaseQueue.appDatabase()
  try await queue.write { _ = try PendingMovie(title: "The Blob").insert($0) }
  var movies = queue.movies()
  let movie = movies[0]
  #expect(movies[0].favorite == false)
  try await queue.write { db in
    var changing = movie
    try changing.toggleFavorite(in: db)
  }

  movies = queue.movies()
  #expect(movies[0].favorite == true)
}

@Test func testMocks() async throws {
  let queue = try DatabaseQueue.appDatabase(mockCount: 13)
  let movies = queue.movies()
  #expect(movies.count == 13)
  #expect(movies[0].title == "Apocalypse Now")
  let actors = queue.actors(for: movies[0])
  #expect(actors.count == 5)
  #expect(actors.csv == "Frederic Forrest, Marlon Brando, Martin Sheen, Robert Duvall, Sam Bottoms")

  let actorMovies = queue.movies(for: actors[1])
  #expect(actorMovies.count == 8)
  #expect(actorMovies.csv == "Apocalypse Now, Don Juan DeMarco, The Godfather, The Island of Dr. Moreau, On the Waterfront, The Score, A Streetcar Named Desire, Superman")
}

@Test func testAppDatabase() async throws {
  try withDependencies {
    $0.context = .live
  } operation: {
    let path = FileManager.default.temporaryDirectory.appending(component: "testAppDatabase_db.sqlite")
    try? FileManager.default.removeItem(at: path)
    let queue = try DatabaseQueue.appDatabase(path: path, mockCount: 13)
    let movies = queue.movies()
    #expect(movies.count == 13)
  }
}

@Test func testAppDatabaseInvalidPath() async throws {
  withDependencies {
    $0.context = .live
  } operation: {
    let path = URL(fileURLWithPath: "/dev/null")
    #expect(throws: Error.self) {
      _ = try DatabaseQueue.appDatabase(path: path)
    }
  }
}

@Test(
  "ActorMoviesQuery Honors Ordering",
  arguments: [
    (SortOrder.forward, "Apocalypse Now, Don Juan DeMarco, The Island of Dr. Moreau, The Score, Superman"),
    (SortOrder.reverse, "Superman, The Score, The Island of Dr. Moreau, Don Juan DeMarco, Apocalypse Now"),
    (nil, "The Score, Superman, The Island of Dr. Moreau, Apocalypse Now, Don Juan DeMarco")
  ]
)
func testActorMoviesQuery(args: (SortOrder?, String)) async throws {
  let queue = try DatabaseQueue.appDatabase(mockCount: 5)
  let actors = queue.actors(ordering: .forward)
  #expect(actors.count == 21)
  #expect(actors[13].name == "Marlon Brando")
  let movies = queue.movies(for: actors[13], ordering: args.0)
  #expect(movies.count == 5)
  #expect(movies.csv == args.1)
}

@Test(
  "MovieActorsQuery Honors Ordering",
  arguments: [
    (SortOrder.forward, "Frederic Forrest, Marlon Brando, Martin Sheen, Robert Duvall, Sam Bottoms"),
    (SortOrder.reverse, "Sam Bottoms, Robert Duvall, Martin Sheen, Marlon Brando, Frederic Forrest"),
    (nil, "Martin Sheen, Marlon Brando, Robert Duvall, Frederic Forrest, Sam Bottoms")
  ]
)
func testMovieActorsQuery(args: (SortOrder?, String)) async throws {
  let queue = try DatabaseQueue.appDatabase(mockCount: 5)
  let movies = queue.movies(ordering: .forward)
  #expect(movies.count == 5)
  #expect(movies[0].title == "Apocalypse Now")
  let actors = queue.actors(for: movies[0], ordering: args.0)
  #expect(actors.count == 5)
  #expect(actors.csv == args.1)
}
