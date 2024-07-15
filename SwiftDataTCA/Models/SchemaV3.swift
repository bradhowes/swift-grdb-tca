import Dependencies
import Foundation
import SwiftData

enum SchemaV3: VersionedSchema {
  static var versionIdentifier: Schema.Version { .init(3, 0, 0) }

  static var models: [any PersistentModel.Type] {
    [Movie.self]
  }

  @Model
  final class Movie {
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
      self.sortableTitle = Self.sortableTitle(title)
    }
  }
}

extension SchemaV3.Movie {
  static let articles = Set(["a", "el", "la", "las", "le", "les", "los", "the", "un", "una"])

  static func sortableTitle(_ title: String) -> String {
    let words = title.lowercased().components(separatedBy: " ")
    if articles.contains(words[0]) {
      return words.dropFirst().joined(separator: " ")
    }
    return title.lowercased()
  }

  static var mock: Movie {
    @Dependency(\.withRandomNumberGenerator) var withRandomNumberGenerator
    @Dependency(\.uuid) var uuid
    let index = withRandomNumberGenerator { generator in
      Int.random(in: 0..<mockData.count, using: &generator)
    }
    let entry = mockData[index]
    return Movie(id: uuid(), title: entry.0, cast: entry.1)
  }
}

extension SchemaV3.Movie: Sendable {}
