import Foundation
import SwiftData

enum MovieSchemaV2: VersionedSchema {
  static var versionIdentifier: Schema.Version { .init(2, 0, 0) }

  static var models: [any PersistentModel.Type] {
    [Movie.self]
  }

  @Model
  final class Movie {
    let id: UUID
    let title: String
    let cast: [String]
    var favorite: Bool = false

    init(id: UUID, title: String, cast: [String], favorite: Bool = false) {
      self.id = id
      self.title = title
      self.cast = cast
      self.favorite = favorite
    }
  }
}

