import ComposableArchitecture
import Foundation
import Models
import SwiftUI

@Reducer
struct FromStateFeature {
  typealias Path = RootFeature.Path

  @ObservableState
  struct State: Equatable {
    var path = StackState<Path.State>()
    var titleSort: SortOrder? = .forward
    @SharedReader var allMovies: IdentifiedArrayOf<Movie>
    var isSearchFieldPresented = false
    var searchText: String = ""
    var scrollTo: Movie?
    var highlight: Movie?

    init(titleSort: SortOrder? = .forward) {
      self.titleSort = titleSort
      _allMovies = Self.makeQuery(titleSort: titleSort)
    }

    static func makeQuery(titleSort: SortOrder?) -> SharedReader<IdentifiedArrayOf<Movie>> {
      SharedReader(.fetch(AllMoviesQuery(ordering: titleSort)))
    }

    mutating func updateQuery() {
      _allMovies = Self.makeQuery(titleSort: titleSort)
    }
  }

  enum Action: Sendable {
    case addButtonTapped
    case clearHighlight
    case clearScrollTo
    case deleteSwiped(Movie)
    case detailButtonTapped(Movie)
    case favoriteSwiped(Movie)
    case highlight(Movie)
    case onAppear
    case path(StackActionOf<Path>)
    case searchButtonTapped(Bool)
    case searchTextChanged(String)
    case titleSortChanged(SortOrder?)
    case toggleFavoriteState(Movie)
  }

  @Dependency(\.defaultDatabase) var database

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {

      case .addButtonTapped:
        let next = Support.nextMockMovieEntry(state.allMovies)
        let movie = try? database.write { try Movie.makeMock(in: $0, entry: next, favorited: false) }
        state.scrollTo = movie
        return .none.animation()

      case .clearHighlight:
        state.highlight = nil
        return .none

      case .clearScrollTo:
        guard let movie = state.scrollTo else {
          return .none
        }

        state.scrollTo = nil
        return .run { @MainActor send in
          send(.highlight(movie), animation: .default)
        }

      case .deleteSwiped(let movie):
        // state.movies = state.movies.filter { $0.id != movie.id }
        _ = try? database.write { db in
          try? movie.delete(db)
        }
        return .none

      case .detailButtonTapped(let movie):
        state.path.append(RootFeature.showMovieActors(movie))
        return .none

      case .favoriteSwiped(let movie):
        return Utils.beginFavoriteChange(.toggleFavoriteState(movie))

      case .highlight(let movie):
        state.highlight = movie
        return .none

      case .onAppear:
        return updateQuery(&state)

      case .path(let pathAction):
        return monitorPathChange(pathAction, state: &state)

      case .searchButtonTapped(let enabled):
        state.isSearchFieldPresented = enabled
        if !enabled {
          state.searchText = ""
        }
        return updateQuery(&state)

      case .searchTextChanged(let query):
        if query != state.searchText {
          state.searchText = query
          return updateQuery(&state)
        }
        return .none

      case .titleSortChanged(let newSort):
        state.titleSort = newSort
        return updateQuery(&state)

      case .toggleFavoriteState(let movie):
        return .none // Utils.toggleFavoriteState(movie, in: &state.movies)
      }
    }
    .forEach(\.path, action: \.path)
  }
}

extension FromStateFeature {

  private func updateQuery(_ state: inout State) -> Effect<Action> {
    state.updateQuery()
    return .none
  }

  private func monitorPathChange(_ pathAction: StackActionOf<Path>, state: inout State) -> Effect<Action> {
    switch pathAction {

      // Detect when the MovieActorsFeature list button is tapped, and show a new ActorMoviesView for the actor that was
      // tapped.
    case .element(id: _, action: .showMovieActors(.detailButtonTapped(let actor))):
      state.path.append(RootFeature.showActorMovies(actor))

      // Detect when the ActorMoviesFeature list button is tapped, and show a new MoveActorsView for the movie that was
      // tapped.
    case .element(id: _, action: .showActorMovies(.detailButtonTapped(let movie))):
      state.path.append(RootFeature.showMovieActors(movie))

      // If we will have popped off all of the detail views, we must refresh our Movies in case it was changed in one
      // of the detail views.
    case .popFrom:
      let count = state.path.count
      if count == 1 {
        return updateQuery(&state)
      }

    default:
      break
    }
    return .none
  }
}

#Preview {
  FromStateView.previewWithButtons
}
