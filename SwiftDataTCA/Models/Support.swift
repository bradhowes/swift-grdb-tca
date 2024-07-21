import Dependencies
import Foundation
import SwiftData

enum Support {

  static let articles = Set(["a", "el", "la", "las", "le", "les", "los", "the", "un", "una"])

  /**
   Drop any initial articles from a title to get reasonable sort results.

   - parameter title: the string value to work with
   - returns: a sortable version of the input value
   */
  static func sortableTitle(_ title: String) -> String {
    let words = title.lowercased().components(separatedBy: " ")
    if articles.contains(words[0]) {
      return words.dropFirst().joined(separator: " ")
    }
    return title.lowercased()
  }

  /// Obtain a random entry from the collection of movie titles and cast members.
  static func nextMockMovieEntry(context: ModelContext, descriptor: FetchDescriptor<Movie>) -> (String, [String]) {
    let count = (try? context.fetchCount(descriptor)) ?? 0
    return mockData[count]
  }

  static func generateMocks(context: ModelContext, count: Int) {
    for index in 0..<20 {
      let movie = ActiveSchema.makeMock(context: context, entry: mockData[index])
      movie.favorite = index % 5 == 0
    }
    try? context.save()
  }

  /**
   Filter a variadic list of optional SortDescriptor instances into an array of non-optional SortDescriptors

   - parameter sortBy: first argument of variadic list
   */
  static func sortBy<M>(_ sortBy: SortDescriptor<M>?...) -> [SortDescriptor<M>] {
    sortBy.compactMap { $0 }
  }

  static func sortedActors(for movie: Movie, order: SortOrder?) -> [Actor] {
    switch order {
    case .forward: return movie.actors.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    case .reverse: return movie.actors.sorted { $0.name.localizedCompare($1.name) == .orderedDescending }
    case nil: return movie.actors
    }
  }

  static func sortedMovies(for actor: Actor, order: SortOrder?) -> [Movie] {
    switch order {
    case .forward: return actor.movies.sorted { $0.sortableTitle.localizedCompare($1.sortableTitle) == .orderedAscending }
    case .reverse: return actor.movies.sorted { $0.sortableTitle.localizedCompare($1.sortableTitle) == .orderedDescending }
    case nil: return actor.movies
    }
  }
}

extension SortDescriptor {

  /**
   Create a SortDescriptor from a key path and a SortOrder value that indicates the order direction.

   - parameter key: the KeyPath of the model attribute to sort on
   - parameter order: the direction of the ordering to perform
   - returns optional SortDescriptor, nil if order is nil
   */
  static func sortBy<M, V: Comparable>(_ key: KeyPath<M, V>, order: SortOrder?) -> SortDescriptor<M>? {
    guard let order else { return nil }
    return .init(key, order: order)
  }
}
