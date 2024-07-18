import Dependencies
import Foundation
import SwiftData

enum SchemaV3: VersionedSchema {
  static var versionIdentifier: Schema.Version { .init(3, 0, 0) }

  static var models: [any PersistentModel.Type] {
    [_Movie.self]
  }

  @Model
  final class _Movie {
    let id: UUID
    let title: String
    let cast: [String]
    var favorite: Bool = false
    var sortableTitle: String = ""

    init(id: UUID, title: String, cast: [String], favorite: Bool = false) {
      self.id = id
      self.title = title
      self.cast = cast
      self.favorite = favorite
      self.sortableTitle = Support.sortableTitle(title)
    }
  }
}

extension SchemaV3._Movie {

  static var mock: SchemaV3._Movie {
    @Dependency(\.uuid) var uuid
    let entry = Support.mockMovieEntry
    return SchemaV3._Movie(id: uuid(), title: entry.0, cast: entry.1)
  }
}

extension SchemaV3._Movie: Sendable {}
