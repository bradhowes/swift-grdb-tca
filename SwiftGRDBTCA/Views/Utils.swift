import ComposableArchitecture
import IdentifiedCollections
import Models
import SwiftUI

enum Ordering: String {
  case forward, reverse, none

  var sortOrder: SortOrder? {
    switch self {
    case .forward: return .forward
    case .reverse: return .reverse
    case .none: return nil
    }
  }
}

enum Utils {

#if os(iOS)

  static func color(_ tag: UIColor) -> Color { Color(uiColor: tag) }

  static let favoriteColor = color(.systemBlue)
  static let titleColor = color(.label)
  static let infoColor = color(.secondaryLabel)
  static let chevronColor = color(.tertiaryLabel)

#elseif os(macOS)

  static func color(_ tag: NSColor) -> Color { Color(nsColor: tag) }

  static let favoriteColor = color(.systemBlue)
  static let titleColor = color(.labelColor)
  static let infoColor = color(.secondaryLabelColor)
  static let chevronColor = color(.tertiaryLabelColor)

#endif

  static func pickerView(title: String, binding: Binding<Ordering>) -> some View {
    Picker(title, systemImage: "arrow.up.arrow.down", selection: binding) {
      Label("Forward", systemImage: "arrow.up")
        .accessibilityLabel("alphabetical \(title)")
        .tag(Ordering.forward)
      Label("Reverse", systemImage: "arrow.down")
        .accessibilityLabel("reverse alphabetical \(title)")
        .tag(Ordering.reverse)
      Label("Unordered", systemImage: "alternatingcurrent")
        .accessibilityLabel("random \(title)")
        .tag(Ordering.none)
    }.pickerStyle(.automatic)
      .accessibilityLabel("choose \(title)")
  }

  struct MovieView: View {
    let name: String
    let favorite: Bool
    let actorNames: String
    var titleColor: Color { favorite ? favoriteColor : Utils.titleColor }

    init(name: String, favorite: Bool, actorNames: String) {
      self.name = name
      self.favorite = favorite
      self.actorNames = actorNames
    }

    var body: some View {
      HStack(spacing: 8) {
        VStack(alignment: .leading) {
          Text(name)
            .font(.headline)
            .foregroundStyle(titleColor)
            .animation(.easeInOut)
            .accessibilityLabel((favorite ? "Favorited " : "") + name)
          Text(actorNames)
            .font(.caption2)
            .foregroundStyle(infoColor)
        }
        Spacer()
        Utils.Chevron()
      }
    }
  }

  struct ActorView: View {
    let name: String
    let movieTitles: String

    init(name: String, movieTitles: String) {
      self.name = name
      self.movieTitles = movieTitles
    }

    var body: some View {
      HStack(spacing: 8) {
        VStack(alignment: .leading) {
          Text(name)
            .font(.headline)
            .foregroundStyle(titleColor)
          Text(movieTitles)
            .font(.caption2)
            .foregroundStyle(infoColor)
        }
        Spacer()
        Utils.Chevron()
      }
    }
  }

  struct Chevron: View {
    var body: some View {
      Image(systemName: "chevron.forward")
        .font(.footnote.bold())
        .foregroundColor(chevronColor)
    }
  }

  static func deleteMovieButton(_ movie: Movie, action: @escaping () -> Void) -> some View {
    Button(role: .destructive, action: action) {
      Image(systemName: "trash")
        .accessibilityLabel(Text("Delete \(movie.title)"))
    }
  }

  static func favoriteMovieButton(_ movie: Movie, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: movie.favorite ? "star.slash" : "star")
        .accessibilityLabel(Text((movie.favorite ? "Unfavorite" : "Favorite") + " movie \(movie.title)"))
    }
    .tint(.blue)
  }

#if os(iOS)
  static func beginFavoriteChange<Action: Sendable>(_ action: Action) -> Effect<Action> {
    @Dependency(\.continuousClock) var clock
    return .run { send in
      // Wait until swiped row is restored -- TODO: there must be a better way to do this
      try await clock.sleep(for: .milliseconds(700))
      await send(action, animation: .default)
    }
  }
#endif // os(iOS)

  static func toggleFavoriteState<Action>(_ movie: inout Movie) -> Effect<Action> {
    @Dependency(\.defaultDatabase) var database
    try? database.write { db in
      movie.favorite.toggle()
      try Movie.update(movie)
        .execute(db)
    }
    return .none
  }
//
//  static func toggleFavoriteState<State>(_ movie: Movie) -> Effect<State> {
//    _ = toggleFavoriteState(movie)
//    return .none
//  }
}
