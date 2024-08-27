import ComposableArchitecture
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
    Picker("", systemImage: "arrow.up.arrow.down", selection: binding) {
      Label("", systemImage: "arrow.up").tag(SortOrder?.some(.forward))
      Label("", systemImage: "arrow.down").tag(SortOrder?.some(.reverse))
      Label("", systemImage: "alternatingcurrent").tag(SortOrder?.none)
    }.pickerStyle(.automatic)
  }

  struct MovieView: View {
    let movie: Movie
    let showChevron: Bool
    var titleColor: Color { movie.favorite ? favoriteColor : Utils.titleColor }
    var actorNames: String { movie.actors(ordering: .forward).map(\.name).formatted(.list(type: .and)) }

    init(movie: Movie, showChevron: Bool) {
      self.movie = movie
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
        actorsList
      }
    }

    private var movieName: some View {
      Text(movie.name)
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
    let actor: Actor
    let showChevron: Bool
    var movieTitles: String { actor.movies(ordering: .forward).map(\.name).formatted(.list(type: .and)) }

    init(actor: Actor, showChevron: Bool) {
      self.actor = actor
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
      Text(actor.name)
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
    Button(action: action) {
      Label("Favorite", systemImage: "star")
    }
    .tint(.blue)
  }

  static func beginFavoriteChange<Action: Sendable>(_ action: Action) -> Effect<Action> {
    @Dependency(\.continuousClock) var clock
    return .run { send in
      try await clock.sleep(for: .milliseconds(700))
      await send(action, animation: .default)
    }
  }

  static func deleteSwipeAction(_ movie: Movie, action: @escaping () -> Void) -> some View {
    Button(role: .destructive, action: action) {
      Label("Delete", systemImage: "trash")
    }
  }

  static func toggleFavoriteState<Action>(_ movie: Movie, movies: inout [Movie]) -> Effect<Action> {
    print("ActorMoviesFeature.toggleFavoriteState - \(movie)")
    let changed = movie.toggleFavorite()
    for (index, movie) in movies.enumerated() where movie.modelId == changed.modelId {
      movies[index] = changed
    }
    return .none
  }

  static func beginFavoriteChange<Action: Sendable>(action: Action) -> Effect<Action> {
    @Dependency(\.continuousClock) var clock
    return .run { send in
      try await clock.sleep(for: .milliseconds(800))
      await send(action, animation: .default)
    }
  }
}
