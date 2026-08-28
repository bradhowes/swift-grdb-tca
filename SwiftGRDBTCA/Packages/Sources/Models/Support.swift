import Dependencies
import Foundation
import GRDB
public import IdentifiedCollections
import StructuredQueriesCore
import Tagged

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
  public var sortable: String { Support.sortableTitle(self) }
}

extension ProcessInfo {
  public var isOnGithub: Bool { !(environment["SNAPSHOT_ARTIFACTS"]?.isEmpty ?? true) }
}

extension Tagged: @retroactive QueryBindable where RawValue: QueryBindable {}

extension Tagged: @retroactive QueryExpression where RawValue: QueryExpression {
  public var queryFragment: QueryFragment { self.rawValue.queryFragment }
}

extension Tagged: @retroactive QueryRepresentable where RawValue: QueryRepresentable {
  public typealias QueryOutput = Tagged<Tag, RawValue.QueryOutput>

  public var queryOutput: QueryOutput { QueryOutput(rawValue: self.rawValue.queryOutput) }

  public init(queryOutput: QueryOutput) { self.init(rawValue: RawValue(queryOutput: queryOutput.rawValue)) }
}

extension Tagged: @retroactive QueryDecodable where RawValue: QueryDecodable {}

extension Tagged: @retroactive _OptionalPromotable where RawValue: _OptionalPromotable {}
