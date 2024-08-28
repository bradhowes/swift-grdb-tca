import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI

@Reducer
struct FromQueryFeature {
  typealias Path = RootFeature.Path

  @ObservableState
  struct State: Equatable {
    let useLinks = true
    var path = StackState<Path.State>()
    var titleSort: SortOrder? = .forward
    var isSearchFieldPresented = false
    var searchText: String = ""
    var scrollTo: Movie?
    var fetchDescriptor: FetchDescriptor<MovieModel> {
      ActiveSchema.movieFetchDescriptor(titleSort: titleSort, search: searchText)
    }
  }

  enum Action: Sendable {
    case addButtonTapped
    case clearScrollTo
    case detailButtonTapped(Movie)
    case deleteSwiped(Movie)
    case favoriteSwiped(Movie)
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
        state.scrollTo = movieModel.valueType
        return .none

      case .clearScrollTo:
        state.scrollTo = nil
        return .none

      case .detailButtonTapped(let movie): return drillDown(movie, state: &state)
      case .deleteSwiped(let movie): return deleteMovie(movie)
      case .favoriteSwiped(let movie): return Utils.beginFavoriteChange(.toggleFavoriteState(movie))
      case .path(let pathAction): return monitorPathChange(pathAction, state: &state)
      case .searchButtonTapped(let enabled): return setSearchMode(enabled, state: &state)
      case .searchTextChanged(let query): return search(query, state: &state)
      case .titleSortChanged(let newSort): return setTitleSort(newSort, state: &state)
      case .toggleFavoriteState(let movie): return toggleFavoriteState(movie)
      }
    }
    .forEach(\.path, action: \.path)
  }
}

extension FromQueryFeature {

  private func deleteMovie(_ movie: Movie) -> Effect<Action> {
    db.delete(movie.backingObject())
    return .none
  }

  private func drillDown(_ movie: Movie, state: inout State) -> Effect<Action> {
    state.isSearchFieldPresented = false
    state.path.append(RootFeature.showMovieActors(movie))
    return .none
  }

  private func monitorPathChange(_ pathAction: StackActionOf<Path>, state: inout State) -> Effect<Action> {
    print("monitorPathChange - \(String(describing: pathAction))")
    switch pathAction {

      // Detect when the MovieActorsFeature list button is tapped, and show a new ActorMoviesView for the actor that was
      // tapped.
    case .element(id: _, action: .showMovieActors(.detailButtonTapped(let actor))):
      state.path.append(RootFeature.showActorMovies(actor))

      // Detect when the ActorMoviesFeature list button is tapped, and show a new MoveActorsView for the movie that was
      // tapped.
    case .element(id: _, action: .showActorMovies(.detailButtonTapped(let movie))):
      state.path.append(RootFeature.showMovieActors(movie))

    default:
      break
    }
    return .none
  }

  private func setSearchMode(_ enabled: Bool, state: inout State) -> Effect<Action> {
    state.isSearchFieldPresented = enabled
    return .none
  }

  private func search(_ query: String, state: inout State) -> Effect<Action> {
    if query != state.searchText {
      state.searchText = query
    }
    return .none
  }

  private func setTitleSort(_ sort: SortOrder?, state: inout State) -> Effect<Action> {
    state.titleSort = sort
    return .none
  }

  private func toggleFavoriteState(_ movie: Movie) -> Effect<Action> {
    _ = movie.toggleFavorite()
    return .none
  }
}
#Preview {
  FromQueryView.preview
}
