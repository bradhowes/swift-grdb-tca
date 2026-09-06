import Dependencies
import Foundation
import GRDB
import Testing
@testable import Models


@Test func testMigration() async throws {
  let db = try appDatabase(rowCount: 13)
  try await db.read {
    _ = try Movie.all.fetchAll($0)
    _ = try Actor.all.fetchAll($0)
    _ = try MovieActor.all.fetchAll($0)
  }
}

@Test func testMovieTable() async throws {
  let db = try appDatabase(rowCount: 13)
  try await db.write {
    try Movie.insert {
      Movie.Draft(title: "Blah Blah", sortableTitle: "blah blah", actorNames: "Abe Normal, Jack Black", favorite: false)
    }
    .execute($0)
  }
  let movies = try await db.read { try Movie.all.fetchAll($0) }
  #expect(movies.count == 14)
  #expect(movies[13].title == "Blah Blah")
}

@Test(
  "Movies FetchKeyRequest Honors Ordering",
  arguments: [
    (SortOrder.forward, ["Apocalypse Now", "The Island of Dr. Moreau", "The Score", "Superman"]),
    (SortOrder.reverse, ["Superman", "The Score", "The Island of Dr. Moreau", "Apocalypse Now"]),
    (nil, ["The Score", "Superman", "The Island of Dr. Moreau", "Apocalypse Now"])
  ]
)
func testMoviesFetchKeyRequest(args: (SortOrder?, [String])) async throws {
  let db = try appDatabase(rowCount: 4)
  let movies = try await db.read { db in try AllMoviesQuery(ordering: args.0).fetch(db) }
  print("expecting: \(args.1) got: \(movies.map(\.title))")
  #expect(movies.count == args.1.count)
  if let _ = args.0 {
    #expect(movies.map(\.title) == args.1)
  }
}
