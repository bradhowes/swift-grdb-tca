import Dependencies
import Foundation
import GRDB


extension DatabaseWriter where Self == DatabaseQueue {

  public static func appDatabase(path: URL? = nil, configuration: Configuration? = nil) throws -> Self {
    var config = configuration ?? Configuration()
#if DEBUG
    config.publicStatementArguments = true
    config.prepareDatabase { db in db.trace { print($0) }}
#endif

    let databaseQueue: DatabaseQueue

    @Dependency(\.context) var context
    if context == .live {
      let dbPath = (path ?? URL.documentsDirectory.appending(component: "db.sqlite")).path()
      print("open", dbPath)
      databaseQueue = try DatabaseQueue(path: dbPath, configuration: config)
    } else {
      databaseQueue = try DatabaseQueue(configuration: config)
    }

    try databaseQueue.migrate()

    return databaseQueue
  }
}

