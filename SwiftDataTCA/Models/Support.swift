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
  static func nextMockMovieEntry(context: ModelContext) -> (String, [String]) {
    mockData[(try? context.fetchCount(ActiveSchema.movieFetchDescriptor())) ?? 0]
  }

  static func generateMocks(context: ModelContext, count: Int) throws {
    for index in 0..<count {
      let movie = ActiveSchema.makeMock(context: context, entry: mockData[index])
      movie.favorite = index % 5 == 0
    }
    try context.save()
  }

  /**
   Filter a variadic list of optional SortDescriptor instances into an array of non-optional SortDescriptors

   - parameter sortBy: first argument of variadic list
   */
  static func sortBy<M>(_ sortBy: SortDescriptor<M>?...) -> [SortDescriptor<M>] {
    sortBy.compactMap { $0 }
  }

  /**
   Obtain the collection of actors associated with a given movie, with the collection ordered by actor names
   according to the given ordering. If ordering is nil, return in the order obtained from the backing store.

   - parameter movie: the model to work with
   - parameter order: the optional ordering to apply to the actor names
   - returns collection of associated ActorModel objects
   */
  static func sortedActors(for movie: MovieModel, order: SortOrder?) -> [ActorModel] {
    switch order {
    case .forward: return movie.actors.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    case .reverse: return movie.actors.sorted { $0.name.localizedCompare($1.name) == .orderedDescending }
    case nil: return movie.actors
    }
  }

  /**
   Obtain the collection of movies associated with a given actor, with the collection ordered by movie sortable titles
   according to the given ordering. If ordering is nil, return in the order obtained from the backing store.

   - parameter actor: the model to work with
   - parameter order: the optional ordering to apply to the movie titles
   - returns collection of associated MovieModel objects
   */
  static func sortedMovies(for actor: ActorModel, order: SortOrder?) -> [MovieModel] {
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
