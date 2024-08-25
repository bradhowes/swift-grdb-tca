import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI

@Reducer
struct FromQueryFeature {
  typealias Path = RootFeature.Path

  @ObservableState
  struct State: Equatable {
    var path = StackState<Path.State>()
    var titleSort: SortOrder? = .forward
    var isSearchFieldPresented = false
    var searchString: String = ""
    var fetchDescriptor: FetchDescriptor<MovieModel> {
      ActiveSchema.movieFetchDescriptor(titleSort: titleSort, searchString: searchString)
    }
  }

  enum Action: Sendable {
    case addButtonTapped
    case searchButtonTapped(Bool)
    case deleteSwiped(Movie)
    case favoriteSwiped(Movie)
    case path(StackActionOf<Path>)
    case searchStringChanged(String)
    case titleSortChanged(SortOrder?)
    case toggleFavoriteState(Movie)
  }

  @Dependency(\.database) var db

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped: return addRandomMovie(state: &state)
      case .deleteSwiped(let movie): return deleteMovie(movie, state: &state)
      case .favoriteSwiped(let movie): return Utils.beginFavoriteChange(.toggleFavoriteState(movie))
      case .path: return .none
      case .searchButtonTapped(let enabled): return setSearchMode(enabled, state: &state)
      case .searchStringChanged(let query): return search(query, state: &state)
      case .titleSortChanged(let newSort): return setTitleSort(newSort, state: &state)
      case .toggleFavoriteState(let movie): return toggleFavoriteState(movie)
      }
    }
    .forEach(\.path, action: \.path)
  }
}

extension FromQueryFeature {

  private func addRandomMovie(state: inout State) -> Effect<Action> {
    _ = db.add()
    return .none
  }

  private func deleteMovie(_ movie: Movie, state: inout State) -> Effect<Action> {
    db.delete(movie.backingObject())
    return .none
  }

  private func setSearchMode(_ enabled: Bool, state: inout State) -> Effect<Action> {
    state.isSearchFieldPresented = enabled
    return .none
  }

  private func search(_ query: String, state: inout State) -> Effect<Action> {
    if query != state.searchString {
      state.searchString = query
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
