import Dependencies
import Foundation
import SwiftData

enum SchemaV2: VersionedSchema {
  static var versionIdentifier: Schema.Version { .init(2, 0, 0) }

  static var models: [any PersistentModel.Type] {
    [_Movie.self]
  }

  @Model
  final class _Movie {
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

extension SchemaV2 {

  static func makeMock(context: ModelContext, entry: (title: String, cast: [String])) {
    @Dependency(\.uuid) var uuid
    let movie = _Movie(id: uuid(), title: entry.title, cast: entry.cast)
    context.insert(movie)
  }

  static func movieFetchDescriptor(
    titleSort: SortOrder?,
    uuidSort: SortOrder?,
    searchString: String
  ) -> FetchDescriptor<_Movie> {
    let sortBy: [SortDescriptor<_Movie>] = [
      sortBy(\.title, order: titleSort),
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

extension SchemaV2._Movie: Sendable {}
