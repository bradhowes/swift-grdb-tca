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

extension SchemaV3 {

  static func movieFetchDescriptor(
    titleSort: SortOrder?,
    uuidSort: SortOrder?,
    searchString: String
  ) -> FetchDescriptor<_Movie> {
    let sortBy: [SortDescriptor<_Movie>] = [
      sortBy(\.sortableTitle, order: titleSort),
      sortBy(\.id, order: uuidSort)
    ].compactMap { $0 }

    let predicate: Predicate<_Movie> = #Predicate<_Movie> {
      searchString.isEmpty ? true : $0.title.localizedStandardContains(searchString)
    }

    return FetchDescriptor(predicate: predicate, sortBy: sortBy)
  }

  static func sortBy<Value: Comparable>(_ key: KeyPath<_Movie, Value>, order: SortOrder?) -> SortDescriptor<_Movie>? {
    guard let order else { return nil }
    return .init(key, order: order)
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
