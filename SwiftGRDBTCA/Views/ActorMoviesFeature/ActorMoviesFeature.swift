import Combine
import ComposableArchitecture
import Foundation
import Models
import Sharing
import SQLiteData
import SwiftUI

@Reducer
struct ActorMoviesFeature {

  @ObservableState
  struct State: Equatable {
    var actor: Actor
    @ObservationStateIgnored
    @Fetch var movies: MovieCollection
    var isSearchFieldPresented = false
    var titleSort: Ordering
    var searchText: String = ""

    init(actor: Actor, titleSort: Ordering = .forward) {
      self.actor = actor
      self.titleSort = titleSort
      self._movies = .init(wrappedValue: [], ActorMoviesQuery(actor: actor, ordering: titleSort.sortOrder))
    }
  }

  enum Action {
    case detailButtonTapped(Movie)
    case favoriteSwiped(Movie)
    case queryUpdated
    case refresh
    case searchButtonTapped(Bool)
    case searchTextChanged(String)
    case titleSortChanged(Ordering)
    case toggleFavoriteState(Movie)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .detailButtonTapped: .none
      case .favoriteSwiped(let movie): favoriteSwiped(&state, movie: movie)
      case .queryUpdated: .none
      case .refresh: refresh(&state)
      case .searchButtonTapped(let enabled): searchButtonTapped(&state, enabled: enabled)
      case .searchTextChanged(let query): searchTextChanged(&state, query: query)
      case .titleSortChanged(let newSort): titleSortChanged(&state, newSort: newSort)
      case .toggleFavoriteState(var movie): Utils.toggleFavoriteState(&movie)
      }
    }
  }
}

extension ActorMoviesFeature {

  private func favoriteSwiped(_ state: inout State, movie: Movie) -> Effect<Action> {
#if os(iOS)
    return Utils.beginFavoriteChange(.toggleFavoriteState(movie))
#endif
#if os(macOS)
    return Utils.toggleFavoriteState(movie)
#endif
  }

  private func refresh(_ state: inout State) -> Effect<Action> {
    @Dependency(\.defaultDatabase) var database
    if let actor = (try? database.read { db in
      try Actor.all.where { $0.id.eq(state.actor.id) }.fetchAll(db)[0]
    }) {
      state.actor = actor
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

  private func titleSortChanged(_ state: inout State, newSort: Ordering) -> Effect<Action> {
    state.titleSort = newSort
    return updateQuery(state)
  }

  private func updateQuery(_ state: State) -> Effect<Action> {
    let searchText = state.searchText.isEmpty ? nil : state.searchText
    let titleSort = state.titleSort
    let actor = state.actor
    let movies = state.$movies
    return .run { send in
      do {
        try await movies.load(
          ActorMoviesQuery(actor: actor, ordering: titleSort.sortOrder, searchText: searchText),
          animation: .smooth
        )
        await send(.queryUpdated)
      } catch {
        reportIssue(error)
      }
    }
    .cancellable(id: "ActorMoviesFeature.updateQuery", cancelInFlight: true)
  }
}

#Preview {
  ActorMoviesView.preview
}
