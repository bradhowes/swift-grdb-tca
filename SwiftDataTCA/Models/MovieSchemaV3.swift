import Foundation
import SwiftData

enum MovieSchemaV3: VersionedSchema {
  static var versionIdentifier: Schema.Version { .init(3, 0, 0) }

  static var models: [any PersistentModel.Type] {
    [Movie.self]
  }

  @Model
  final class Movie: Sendable {
    let id: UUID
    let title: String
    let cast: [String]
    var favorite: Bool = false
    var sortableTitle: String = ""

    init(title: String, cast: [String], favorite: Bool = false) {
      self.id = UUID()
      self.title = title
      self.cast = cast
      self.favorite = favorite
      self.sortableTitle = Self.sortableTitle(title)
    }
  }
}

extension MovieSchemaV3.Movie {
  static let articles = Set(["a", "el", "la", "las", "le", "les", "los", "the"])

  static func sortableTitle(_ title: String) -> String {
    let words = title.lowercased().components(separatedBy: " ")
    if articles.contains(words[0]) {
      return words.dropFirst().joined(separator: " ")
    }
    return title.lowercased()
  }
}
