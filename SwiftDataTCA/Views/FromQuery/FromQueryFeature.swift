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
    var highlight: Movie?
    var fetchDescriptor: FetchDescriptor<MovieModel> {
      ActiveSchema.movieFetchDescriptor(titleSort: titleSort, search: searchText)
    }
  }

  enum Action: Sendable {
    case addButtonTapped
    case clearHighlight
    case clearScrollTo
    case detailButtonTapped(Movie)
    case deleteSwiped(Movie)
    case favoriteSwiped(Movie)
    case highlight(Movie)
    case path(StackActionOf<Path>)
    case scrollTo(Movie)
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
        return .run { @MainActor send in send(.scrollTo(movieModel.valueType)) }

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

      case .path(let pathAction):
        return monitorPathChange(pathAction, state: &state)

      case .searchButtonTapped(let enabled):
        state.isSearchFieldPresented = enabled
        return .none

      case .searchTextChanged(let query):
        if query != state.searchText {
          state.searchText = query
        }
        return .none

      case .scrollTo(let movie):
        state.scrollTo = movie
        return .none

      case .titleSortChanged(let newSort):
        state.titleSort = newSort
        return .none

      case .toggleFavoriteState(let movie):
        _ = movie.toggleFavorite()
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}

extension FromQueryFeature {

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
}

#Preview {
  FromQueryView.preview
}
