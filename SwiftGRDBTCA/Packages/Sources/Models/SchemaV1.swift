import Dependencies
import Foundation
import GRDB
import IdentifiedCollections
import SharedGRDB
import Tagged

/// Temporary record that represents a Movie prior to being inserted into the database. Saves us from having to play
/// games with the `Movie.id` attribute.
public struct PendingMovie: Codable, FetchableRecord, PersistableRecord {

  public let title: String
  public let sortableTitle: String
  public let favorite: Bool

  public init(title: String) {
    self.title = title
    self.sortableTitle = Support.sortableTitle(title)
    self.favorite = false
  }

  public static let databaseTableName: String = "movies"
}

/// Representation of a `Movie` row in the database.
public struct Movie: Codable, Identifiable, FetchableRecord, MutablePersistableRecord {
  public typealias ID = Tagged<Self, Int64>

  public let id: ID
  public let title: String
  public let sortableTitle: String
  public var favorite: Bool

  public mutating func toggleFavorite(in db: Database) throws {
    favorite.toggle()
    try update(db)
  }

  public static let databaseTableName: String = PendingMovie.databaseTableName
}

extension Movie {
  public enum Columns {
    public static let id = Column(CodingKeys.id)
    public static let title = Column(CodingKeys.title)
    public static let sortableTitle = Column(CodingKeys.sortableTitle)
    public static let favorite = Column(CodingKeys.favorite)
  }

  static func createTable(in db: Database) throws {
    try db.create(table: Self.databaseTableName) { table in
      table.autoIncrementedPrimaryKey(Columns.id)
      table.column(Columns.title, .text).notNull()
      table.column(Columns.sortableTitle, .text).notNull().unique()
      table.column(Columns.favorite, .boolean).defaults(to: false)
    }
    try db.create(virtualTable: "movie_ft", using: FTS5()) { table in
      table.synchronize(withTable: Movie.databaseTableName)
      table.column(Movie.Columns.title.name)
    }
  }
}

extension Movie: Hashable, Sendable {}
public typealias MovieCollection = IdentifiedArrayOf<Movie>

public struct PendingActor: Codable, FetchableRecord, PersistableRecord {
  public let name: String

  public static let databaseTableName: String = "actors"
}

public struct Actor: Codable, Identifiable, FetchableRecord, MutablePersistableRecord {
  public typealias ID = Tagged<Self, Int64>

  public let id: ID
  public let name: String

  public static func fetchOrCreate(in db: Database, name: String) throws -> Actor {
    let existing = try Actor.all().filter(Actor.Columns.name == name).fetchAll(db)
    if !existing.isEmpty {
      return existing[0]
    }
    return try PendingActor(name: name).insertAndFetch(db, as: Actor.self)
  }

  public static let databaseTableName: String = PendingActor.databaseTableName
}

extension Actor {
  public enum Columns {
    public static let id = Column(CodingKeys.id)
    public static let name = Column(CodingKeys.name)
  }

  static func createTable(in db: Database) throws {
    try db.create(table: Self.databaseTableName) { table in
      table.autoIncrementedPrimaryKey(Columns.id)
      table.column(Columns.name, .text).notNull().unique()
    }
  }
}

extension Actor: Hashable, Sendable {}
public typealias ActorCollection = IdentifiedArrayOf<Actor>

public struct MovieActor: Codable, FetchableRecord, PersistableRecord {
  public let moviesId: Movie.ID
  public let actorsId: Actor.ID

  static func createTable(in db: Database) throws {
    try db.create(table: MovieActor.databaseTableName) { table in
      table.primaryKey {
        table.belongsTo(Actor.databaseTableName, onDelete: .cascade)
        table.belongsTo(Movie.databaseTableName, onDelete: .cascade)
      }
    }
  }

  public static let databaseTableName: String = "movieActors"
}

extension MovieActor {
  static let movie = belongsTo(Movie.self)
  static let actor = belongsTo(Actor.self)
}

extension Movie {
  static let movieActors = hasMany(MovieActor.self)
  static let actors = hasMany(Actor.self, through: movieActors, using: MovieActor.actor)
  static let fullText = hasOne(Table("movie_ft"), using: ForeignKey([.rowID], to: [.rowID]))
  public var actors: QueryInterfaceRequest<Actor> { request(for: Movie.actors) }
}

extension Actor {
  static let movieArtists = hasMany(MovieActor.self)
  static let movies = hasMany(Movie.self, through: movieArtists, using: MovieActor.movie)

  public var movies: QueryInterfaceRequest<Movie> { request(for: Actor.movies) }
}

extension Movie {

  public static func makeMock(in db: Database, entry: (String, [String]), favorited: Bool) throws -> Movie {
    let movie = try PendingMovie(title: entry.0).insertAndFetch(db, as: Movie.self)
    for name in entry.1 {
      let actor = try Actor.fetchOrCreate(in: db, name: name)
      try MovieActor(moviesId: movie.id, actorsId: actor.id).insert(db)
    }
    return movie
  }
}

func migration(_ db: Database) throws {
  try Movie.createTable(in: db)
  try Actor.createTable(in: db)
  try MovieActor.createTable(in: db)
}

extension DatabaseWriter {

  func migrate() throws {
    var migrator = DatabaseMigrator()

#if DEBUG
    migrator.eraseDatabaseOnSchemaChange = true
#endif

    migrator.registerMigration("SchemaV1") { db in
      try migration(db)

#if targetEnvironment(simulator)
      if !isTesting {
        try Movie.deleteAll(db)
        try Actor.deleteAll(db)
        try MovieActor.deleteAll(db) // just to be safe
      }
#endif
    }

    try migrator.migrate(self)
  }
}

extension DerivableRequest<Movie> {
  public func matching(_ pattern: FTS5Pattern?) -> Self {
    joining(required: Movie.fullText.matching(pattern))
  }
}

extension TableDefinition {

  @discardableResult
  func autoIncrementedPrimaryKey(_ column: Column) -> ColumnDefinition {
    autoIncrementedPrimaryKey(column.name)
  }

  @discardableResult
  func column(_ name: Column, _ kind: Database.ColumnType?) -> ColumnDefinition {
    column(name.name, kind)
  }
}

extension Tagged: @retroactive SQLExpressible
where RawValue: SQLExpressible {}

extension Tagged: @retroactive StatementBinding
where RawValue: StatementBinding {}

extension Tagged: @retroactive StatementColumnConvertible
where RawValue: StatementColumnConvertible {}

extension Tagged: @retroactive DatabaseValueConvertible
where RawValue: DatabaseValueConvertible {}
