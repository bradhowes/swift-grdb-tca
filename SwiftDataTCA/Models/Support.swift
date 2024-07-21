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
  static var mockMovieEntry: (String, [String]) {
    @Dependency(\.withRandomNumberGenerator) var withRandomNumberGenerator
    let index = withRandomNumberGenerator { generator in
      Int.random(in: 0..<mockData.count, using: &generator)
    }
    return mockData[index]
  }

  /**
   Filter a variadic list of optional SortDescriptor instances into an array of non-optional SortDescriptors

   - parameter sortBy: first argument of variadic list
   */
  static func sortBy<M>(_ sortBy: SortDescriptor<M>?...) -> [SortDescriptor<M>] {
    sortBy.compactMap { $0 }
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
