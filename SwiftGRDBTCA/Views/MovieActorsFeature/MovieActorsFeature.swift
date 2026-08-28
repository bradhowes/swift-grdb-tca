import ComposableArchitecture
import Dependencies
import Foundation
import IdentifiedCollections
import Models
import SQLiteData
import SwiftUI

@Reducer
struct MovieActorsFeature {

  @ObservableState
  struct State: Equatable {
    var movie: Movie
    @ObservationStateIgnored
    @Fetch var actors: ActorCollection
    var isSearchFieldPresented = false
    var animateButton = false
    var nameSort: Ordering
    var searchText: String = ""

    init(movie: Movie, nameSort: Ordering = .forward) {
      self.movie = movie
      self.nameSort = nameSort
      self._actors = .init(wrappedValue: [], MovieActorsQuery(movie: movie, ordering: nameSort.sortOrder))
    }
  }

  enum Action {
    case detailButtonTapped(Actor)
    case favoriteTapped
    case nameSortChanged(Ordering)
    case refresh
    case searchButtonTapped(Bool)
    case searchTextChanged(String)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .detailButtonTapped: return .none

      case .favoriteTapped:
        state.animateButton = !state.movie.favorite
        return Utils.toggleFavoriteState(&state.movie)

      case .nameSortChanged(let newSort): return setNameSort(newSort, state: &state)
      case .refresh: return refresh(&state)

      case .searchButtonTapped(let enabled):
        state.isSearchFieldPresented = enabled
        if !enabled {
          state.searchText = ""
          return updateQuery(state)
        }
        return .none

      case .searchTextChanged(let query):
        if query != state.searchText {
          state.searchText = query
          return updateQuery(state)
        }
        return .none
      }
    }
  }
}

extension MovieActorsFeature {

  private func refresh(_ state: inout State) -> Effect<Action> {
    @Dependency(\.defaultDatabase) var database
    if let movie = (try? database.read { db in
      try Movie.all.where { $0.id.eq(state.movie.id) }.fetchAll(db)[0]
    }) {
      state.movie = movie
    }
    return .none
  }

  private func setNameSort(_ newSort: Ordering, state: inout State) -> Effect<Action> {
    state.nameSort = newSort
    return updateQuery(state)
  }

  private func updateQuery(_ state: State) -> Effect<Action> {
    let searchText = state.searchText.isEmpty ? nil : state.searchText
    let nameSort = state.nameSort
    let movie = state.movie
    let actors = state.$actors
    return .run { _ in
      do {
        try await actors.load(
          MovieActorsQuery(movie: movie, ordering: nameSort.sortOrder, searchText: searchText),
          animation: .smooth
        )
      } catch {
        reportIssue(error)
      }
    }
    .cancellable(id: "MovieActorsFeature.updateQuery", cancelInFlight: true)
  }
}

#Preview {
  MovieActorsView.preview
}
