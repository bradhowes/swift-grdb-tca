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
    case queryUpdated
    case refresh
    case searchButtonTapped(Bool)
    case searchTextChanged(String)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .detailButtonTapped: .none
      case .favoriteTapped: favoriteTapped(&state)
      case .nameSortChanged(let newSort): setNameSort(newSort, state: &state)
      case .queryUpdated: .none
      case .refresh: refresh(&state)
      case .searchButtonTapped(let enabled): searchButtonTapped(&state, enabled: enabled)
      case .searchTextChanged(let query): searchTextChanged(&state, query: query)
      }
    }
  }
}

extension MovieActorsFeature {

  private func favoriteTapped(_ state: inout State) -> Effect<Action> {
    state.animateButton = !state.movie.favorite
    return Utils.toggleFavoriteState(&state.movie)
  }

  private func refresh(_ state: inout State) -> Effect<Action> {
    @Dependency(\.defaultDatabase) var database
    if let movie = (try? database.read { db in
      try Movie.all.where { $0.id.eq(state.movie.id) }.fetchAll(db)[0]
    }) {
      state.movie = movie
    }
    return .none
  }

  private func searchButtonTapped(_ state: inout State, enabled: Bool) -> Effect<Action> {
    state.isSearchFieldPresented = enabled
    if !enabled {
      state.searchText = ""
      return updateQuery(state)
    }
    return .none
  }

  private func searchTextChanged(_ state: inout State, query: String) -> Effect<Action> {
    if query != state.searchText {
      state.searchText = query
      return updateQuery(state)
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
    return .run { send in
      do {
        try await actors.load(
          MovieActorsQuery(movie: movie, ordering: nameSort.sortOrder, searchText: searchText),
          animation: .smooth
        )
        await send(.queryUpdated)
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
