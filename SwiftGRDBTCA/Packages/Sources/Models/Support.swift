import Dependencies
import Foundation
import GRDB
public import IdentifiedCollections

public enum Support {

  public static let articles = Set(["a", "el", "la", "las", "le", "les", "los", "the", "un", "una"])

  /**
   Drop any initial articles from a title to get reasonable sort results.

   - parameter title: the string value to work with
   - returns: a sortable version of the input value
   */
  public static func sortableTitle(_ title: String) -> String {
    title.lowercased().components(separatedBy: " ")
      .compactMap { articles.contains($0) ? nil : $0 }
      .joined(separator: " ")
      .lowercased()
  }

  /// Obtain an entry from the collection of movie titles and cast members.
  public static func nextMockMovieEntry(_ movies: IdentifiedArrayOf<Movie>) -> (String, [String]) {
    let titles = Set(movies.map { $0.sortableTitle })
    for index in 0..<mockData.count {
      let (title, cast) = mockData[index]
      let stitle = title.sortable
      if !titles.contains(stitle) {
        return (title, cast)
      }
    }
    fatalError("ran out of mock data!")
  }

  public static func generateRows(db: Database, count: Int) throws {
    for index in 0..<count {
      _ = try Movie.make(db: db, entry: mockData[index])
    }
  }
}

extension String {
  nonisolated public var sortable: String { Support.sortableTitle(self) }

  nonisolated public var quoted: String {
    // Split into words
    split(separator: " ")
    // Replace a single double-quote with two. Wrap the result in double-quotes, and add a '*' to enable
    // prefix matching on words.
      .map { #""\#($0.replacingOccurrences(of: #"""#, with: #""""#))"*"# }
    // Build string from words
      .joined(separator: " ")
  }
}
                                                 
extension ProcessInfo {
  public var isOnGithub: Bool { !(environment["SNAPSHOT_ARTIFACTS"]?.isEmpty ?? true) }
}
