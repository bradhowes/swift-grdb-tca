import Dependencies
import Foundation
import SwiftData

enum Support {

  static let articles = Set(["a", "el", "la", "las", "le", "les", "los", "the", "un", "una"])

  static func sortableTitle(_ title: String) -> String {
    let words = title.lowercased().components(separatedBy: " ")
    if articles.contains(words[0]) {
      return words.dropFirst().joined(separator: " ")
    }
    return title.lowercased()
  }

  static var mockMovieEntry: (String, [String]) {
    @Dependency(\.withRandomNumberGenerator) var withRandomNumberGenerator
    let index = withRandomNumberGenerator { generator in
      Int.random(in: 0..<mockData.count, using: &generator)
    }
    return mockData[index]
  }
}
