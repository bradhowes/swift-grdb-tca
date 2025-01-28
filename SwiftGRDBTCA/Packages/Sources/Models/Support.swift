import Dependencies
import Foundation
import GRDB
import IdentifiedCollections


public enum Support {

  public static let articles = Set(["a", "el", "la", "las", "le", "les", "los", "the", "un", "una"])

  /**
   Drop any initial articles from a title to get reasonable sort results.

   - parameter title: the string value to work with
   - returns: a sortable version of the input value
   */
  public static func sortableTitle(_ title: String) -> String {
    let words = title.lowercased().components(separatedBy: " ")
    if articles.contains(words[0]) {
      return words.dropFirst().joined(separator: " ")
    }
    return title.lowercased()
  }

  /// Obtain an entry from the collection of movie titles and cast members.
  public static func nextMockMovieEntry(_ movies: IdentifiedArrayOf<Movie>) -> (String, [String]) {
    let titles = Set(movies.map { $0.sortableTitle })
    for index in 0..<mockData.count {
      let (title, cast) = mockData[index]
      let stitle = sortableTitle(title)
      if !titles.contains(stitle) {
        print("next entry:", title, cast)
        return (title, cast)
      }
    }
    fatalError("ran out of mock data!")
  }

  public static func generateMocks(db: Database, count: Int) throws {
    for index in 0..<count {
      _ = try Movie.makeMock(in: db, entry: mockData[index], favorited: index % 5 == 0)
    }
  }
}
