import Foundation
import SwiftData

enum MovieSchemaV1: VersionedSchema {
  static var versionIdentifier: Schema.Version { .init(1, 0, 0) }

  static var models: [any PersistentModel.Type] {
    [Movie.self]
  }

  @Model
  final class Movie: Identifiable {
    var id: UUID
    var title: String
    var cast: [String]

    init(title: String, cast: [String]) {
      self.id = UUID()
      self.title = title
      self.cast = cast
    }
  }
}
