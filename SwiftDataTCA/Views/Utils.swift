import ComposableArchitecture
import IdentifiedCollections
import SwiftData
import SwiftUI

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

  static func pickerView(title: String, binding: Binding<SortOrder?>) -> some View {
    Picker(title, systemImage: "arrow.up.arrow.down", selection: binding) {
      Label("Alphabetical", systemImage: "arrow.up")
        .accessibilityLabel("alphabetical \(title)")
        .tag(SortOrder?.some(.forward))
      Label("Reverse alphabetical", systemImage: "arrow.down")
        .accessibilityLabel("reverse alphabetical \(title)")
        .tag(SortOrder?.some(.reverse))
      Label("Unordered", systemImage: "alternatingcurrent")
        .accessibilityLabel("random \(title)")
        .tag(SortOrder?.none)
    }.pickerStyle(.automatic)
      .accessibilityLabel("choose \(title)")
  }

  struct MovieView: View {
    let name: String
    let favorite: Bool
    let actorNames: String
    let showChevron: Bool
    var titleColor: Color { favorite ? favoriteColor : Utils.titleColor }

    init(name: String, favorite: Bool, actorNames: String, showChevron: Bool) {
      self.name = name
      self.favorite = favorite
      self.actorNames = actorNames
      self.showChevron = showChevron
    }

    var body: some View {
      if showChevron {
        withChevron
      } else {
        movieEntry
      }
    }

    private var withChevron: some View {
      HStack(spacing: 8) {
        movieEntry
        Spacer()
        Utils.chevron
      }
    }

    private var movieEntry: some View {
      VStack(alignment: .leading) {
        movieName
          .accessibilityLabel((favorite ? "Favorited " : "") + name)
        actorsList
      }
    }

    private var movieName: some View {
      Text(name)
        .font(.headline)
        .foregroundStyle(titleColor)
        .animation(.easeInOut)
    }

    private var actorsList: some View {
      Text(actorNames)
        .font(.caption2)
        .foregroundStyle(infoColor)
    }
  }

  struct ActorView: View {
    let name: String
    let movieTitles: String
    let showChevron: Bool

    init(name: String, movieTitles: String, showChevron: Bool) {
      self.name = name
      self.movieTitles = movieTitles
      self.showChevron = showChevron
    }

    var body: some View {
      if showChevron {
        withChevron
      } else {
        actorEntry
      }
    }

    private var withChevron: some View {
      HStack(spacing: 8) {
        actorEntry
        Spacer()
        Utils.chevron
      }
    }

    private var actorEntry: some View {
      VStack(alignment: .leading) {
        actorName
        moviesList
      }
    }

    var actorName: some View {
      Text(name)
        .font(.headline)
        .foregroundStyle(Utils.titleColor)
    }

    var moviesList: some View {
      Text(movieTitles)
        .font(.caption2)
        .foregroundStyle(infoColor)
    }
  }

  static var chevron: some View {
    Image(systemName: "chevron.forward")
      .font(.footnote.bold())
      .foregroundColor(Color(UIColor.tertiaryLabel))
  }

  static func favoriteSwipeAction(_ movie: Movie, action: @escaping () -> Void) -> some View {
    if movie.favorite {
      Button(action: action) {
        Label("unfavorite movie", systemImage: "star.fill")
      }
      .tint(.blue)
    } else {
      Button(action: action) {
        Label("favorite movie", systemImage: "star")
      }
      .tint(.blue)
    }
  }

  static func actorNamesList(for movie: Movie) -> String {
    movie.actors(ordering: .forward).map(\.name).formatted(.list(type: .and))
  }

  static func movieTitlesList(for actor: Actor) -> String {
    actor.movies(ordering: .forward).map(\.name).formatted(.list(type: .and))
  }

  static func beginFavoriteChange<Action: Sendable>(_ action: Action) -> Effect<Action> {
    @Dependency(\.continuousClock) var clock
    return .run { send in
      // Wait until swiped row is restored
      try await clock.sleep(for: .milliseconds(700))
      await send(action, animation: .default)
    }
  }

  static func deleteSwipeAction(_ movie: Movie, action: @escaping () -> Void) -> some View {
    Button(role: .destructive, action: action) {
      Label("Delete", systemImage: "trash")
    }
  }

  static func toggleFavoriteState<Action>(_ movie: Movie, movies: inout IdentifiedArrayOf<Movie>) -> Effect<Action> {
    let changed = movie.toggleFavorite()
    for (index, movie) in movies.enumerated() where movie.modelId == changed.modelId {
      movies[index] = changed
    }
    return .none
  }
}
