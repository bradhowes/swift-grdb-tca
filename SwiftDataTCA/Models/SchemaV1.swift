import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
  static var versionIdentifier: Schema.Version { .init(1, 0, 0) }

  static var models: [any PersistentModel.Type] {
    [Movie.self]
  }

  @Model
  final class Movie: Identifiable {
    let id: UUID
    let title: String
    let cast: [String]

    init(id: UUID, title: String, cast: [String]) {
      self.id = id
      self.title = title
      self.cast = cast
    }
  }
}
