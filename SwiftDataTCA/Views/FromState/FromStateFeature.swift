import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI

@Reducer
struct FromStateFeature {
  typealias Path = RootFeature.Path

  @ObservableState
  struct State: Equatable {
    var path = StackState<Path.State>()
    var movies: IdentifiedArrayOf<Movie> = []
    var titleSort: SortOrder? = .forward
    var isSearchFieldPresented = false
    var searchText: String = ""
    var scrollTo: Movie?
    var highlight: Movie?
    var fetchDescriptor: FetchDescriptor<MovieModel> {
      ActiveSchema.movieFetchDescriptor(titleSort: self.titleSort, search: searchText)
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

  @Dependency(\.database) var db

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {

      case .addButtonTapped:
        let movieModel = db.add()
        return fetchMovies(movieModel.valueType, state: &state)

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
        state.movies = state.movies.filter { $0.id != movie.id }
        db.delete(movie.backingObject())
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
        return fetchMovies(nil, state: &state)

      case .path(let pathAction):
        return monitorPathChange(pathAction, state: &state)

      case .searchButtonTapped(let enabled):
        state.isSearchFieldPresented = enabled
        if !enabled {
          state.searchText = ""
        }
        return fetchMovies(nil, state: &state)

      case .searchTextChanged(let query):
        if query != state.searchText {
          state.searchText = query
          return fetchMovies(nil, state: &state)
        }
        return .none

      case .titleSortChanged(let newSort):
        state.titleSort = newSort
        return fetchMovies(nil, state: &state)

      case .toggleFavoriteState(let movie):
        return Utils.toggleFavoriteState(movie, movies: &state.movies)
      }
    }
    .forEach(\.path, action: \.path)
  }
}

extension FromStateFeature {

  private func fetchMovies(_ movie: Movie?, state: inout State) -> Effect<Action> {
    @Dependency(\.database) var db
    state.movies = .init(uncheckedUniqueElements: db.fetchMovies(state.fetchDescriptor).map(\.valueType))
    if let movie {
      state.scrollTo = movie
    }
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
        return fetchMovies(nil, state: &state)
      }

    default:
      break
    }
    return .none
  }
}

#Preview {
  FromStateView.previewWithLinks
}

#Preview {
  FromStateView.previewWithButtons
}
