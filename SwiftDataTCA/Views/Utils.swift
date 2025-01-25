import ComposableArchitecture
import IdentifiedCollections
import Models
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
    @Dependency(\.defaultDatabase) var database
    do {
      let actors = try database.read { try movie.actors.order(Actor.Columns.name.asc).fetchAll($0) }
      let names = actors.map(\.name).joined(separator: ", ")
      print("actorNamesList:", names)
      return names
    } catch {
      fatalError("failed to fetch actors of movie \(movie.title): \(error)")
    }
  }

  static func movieTitlesList(for actor: Actor) -> String {
    @Dependency(\.defaultDatabase) var database
    do {
      let movies = try database.read { try actor.movies.order(Movie.Columns.sortableTitle.asc).fetchAll($0) }
      let titles = movies.map(\.title).joined(separator: ", ")
      print("movieTitlesList:", titles)
      return titles
    } catch {
      fatalError("failed to fetch movies of actor \(actor.name): \(error)")
    }
  }

  static func beginFavoriteChange<Action: Sendable>(_ action: Action) -> Effect<Action> {
    @Dependency(\.continuousClock) var clock
    return .run { send in
      // Wait until swiped row is restored -- TODO: there must be a better way to do this
      try await clock.sleep(for: .milliseconds(700))
      await send(action, animation: .default)
    }
  }

  static func deleteSwipeAction(_ movie: Movie, action: @escaping () -> Void) -> some View {
    Button(role: .destructive, action: action) {
      Label("Delete", systemImage: "trash")
    }
  }

  static func toggleFavoriteState(_ movie: Movie) -> Movie {
    @Dependency(\.defaultDatabase) var database
    var changed: Movie = movie
    try? database.write { try changed.toggleFavorite(in: $0) }
    return changed
  }

  static func toggleFavoriteState<State>(_ movie: Movie) -> Effect<State> {
    let _ = toggleFavoriteState(movie)
    return .none
  }
}
