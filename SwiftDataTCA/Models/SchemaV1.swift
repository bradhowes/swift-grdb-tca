import Dependencies
import Foundation
import GRDB
import IdentifiedCollections
import Tagged

extension SortOrder {
  func by(_ column: Column) -> SQLOrdering {
    switch self {
    case .forward: return column.collating(.localizedCaseInsensitiveCompare).asc
    case .reverse: return column.collating(.localizedCaseInsensitiveCompare).desc
    }
  }
}

struct PendingMovie: Codable, FetchableRecord, PersistableRecord {
  let title: String
  let sortableTitle: String
  let favorite: Bool

  init(title: String) {
    self.title = title
    self.sortableTitle = Support.sortableTitle(title)
    self.favorite = false
  }

  static let databaseTableName: String = "movies"
}

struct Movie: Codable, Hashable, Identifiable, FetchableRecord, MutablePersistableRecord {
  typealias ID = Tagged<Self, Int64>

  let id: ID
  let title: String
  let sortableTitle: String
  var favorite: Bool

  static let databaseTableName: String = PendingMovie.databaseTableName

  mutating func toggleFavorite() {
    favorite.toggle()
    @Dependency(\.defaultDatabase) var database
    do {
      try database.write { db in
        try update(db)
      }
    } catch {
      fatalError("failed to update movie favorite - \(error)")
    }
  }
}

extension Movie {
  enum Columns {
    static let id = Column(CodingKeys.id)
    static let title = Column(CodingKeys.title)
    static let sortableTitle = Column(CodingKeys.sortableTitle)
    static let favorite = Column(CodingKeys.favorite)
  }

  static func createTable(in db: Database) throws {
    try db.create(table: Self.databaseTableName) { table in
      table.autoIncrementedPrimaryKey(Columns.id)
      table.column(Columns.title, .text).notNull()
      table.column(Columns.sortableTitle, .text).notNull().unique()
      table.column(Columns.favorite, .boolean).defaults(to: false)
    }
  }
}

struct Movies: FetchKeyRequest {
  let ordering: SortOrder

  init(ordering: SortOrder = .forward) {
    self.ordering = ordering
  }

  func fetch(_ db: Database) throws -> [Movie] {
    try Movie
      .all()
      .order(Movie.Columns.sortableTitle.collating(.localizedCaseInsensitiveCompare).asc)
      .fetchAll(db)
  }
}

struct PendingActor: Codable, FetchableRecord, PersistableRecord {
  let name: String

  static let databaseTableName: String = "actors"
}

struct Actor: Codable, Hashable, Identifiable, FetchableRecord, MutablePersistableRecord {
  typealias ID = Tagged<Self, Int64>

  let id: ID
  let name: String

  static func fetchOrCreate(in db: Database, name: String) throws -> Actor {
    if let existing = try fetchOne(db, key: name) {
      return existing
    }
    return try PendingActor(name: name).insertAndFetch(db, as: Actor.self)
  }
}

extension Actor {
  enum Columns {
    static let id = Column(CodingKeys.id)
    static let name = Column(CodingKeys.name)
  }

  static func createTable(in db: Database) throws {
    try db.create(table: Self.databaseTableName) { table in
      table.autoIncrementedPrimaryKey(Columns.id)
      table.column(Columns.name, .text).notNull().unique()
    }
  }

  static let databaseTableName: String = PendingActor.databaseTableName
}

struct MovieActor: Codable, FetchableRecord, PersistableRecord {
  var movieId: Movie.ID
  var actorId: Actor.ID

  static func createTable(in db: Database) throws {
    try db.create(table: MovieActor.databaseTableName) { table in
      table.primaryKey {
        table.belongsTo(Actor.databaseTableName, onDelete: .cascade)
        table.belongsTo(Movie.databaseTableName, onDelete: .cascade)
      }
    }
  }

  static let databaseTableName: String = "movieActors"
}

extension MovieActor {
  static let movie = belongsTo(Movie.self)
  static let actor = belongsTo(Actor.self)
}

extension Movie {
  static let movieActors = hasMany(MovieActor.self)
  static let actors = hasMany(Actor.self, through: movieActors, using: MovieActor.actor)

  var actors: QueryInterfaceRequest<Actor> { request(for: Movie.actors) }
}

extension Actor {
  static let movieArtists = hasMany(MovieActor.self)
  static let movies = hasMany(Movie.self, through: movieArtists, using: MovieActor.movie)

  var movies: QueryInterfaceRequest<Movie> { request(for: Actor.movies) }
}

struct Actors: FetchKeyRequest {
  let ordering: SortOrder

  init(ordering: SortOrder = .forward) {
    self.ordering = ordering
  }

  func fetch(_ db: Database) throws -> [Actor] {
    try Actor
      .all()
      .order(ordering.by(Actor.Columns.name))
      .fetchAll(db)
  }
}

struct ActorMovies: FetchKeyRequest {
  let actor: Actor

  init(actor: Actor, ordering: SortOrder) {
    self.actor = actor
  }

  func fetch(_ db: Database) throws -> [Movie] {
    try actor.movies.fetchAll(db)
  }
}

struct MovieActors: FetchKeyRequest {
  let movie: Movie

  func fetch(_ db: Database) throws -> [Actor] {
    try movie.actors.fetchAll(db)
  }
}

extension Movie {

  static func makeMock(in db: Database, entry: (String, [String]), favorited: Bool) throws {
    let movie = try PendingMovie(title: entry.0).insertAndFetch(db, as: Movie.self)
    for name in entry.1 {
      let actor = try Actor.fetchOrCreate(in: db, name: name)
      try MovieActor(movieId: movie.id, actorId: actor.id).insert(db)
    }
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
        try Support.generateMocks(db: db, count: 13)
      }
#endif
    }

    try migrator.migrate(self)
  }
}

extension DatabaseWriter where Self == DatabaseQueue {

  static var appDatabase: Self {
    var configuration = Configuration()
    configuration.prepareDatabase { db in
      db.trace { event in
        print(event)
      }
    }

    let databaseQueue: DatabaseQueue
    do {
      @Dependency(\.context) var context
      if context == .live {
        let path = URL.documentsDirectory.appending(component: "db.sqlite").path()
        print("open", path)
        databaseQueue = try DatabaseQueue(path: path, configuration: configuration)
      } else {
        databaseQueue = try DatabaseQueue(configuration: configuration)
      }
      try databaseQueue.migrate()
    } catch {
      fatalError("failed to create database - \(error)")
    }
    return databaseQueue
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

// extension WritableKeyPath<DependencyValues, any DatabaseWriter>: @unchecked @retroactive Sendable {}
