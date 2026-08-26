import Combine
import ComposableArchitecture
import Foundation
import Models
import Sharing
import SwiftUI

@Reducer
struct ActorMoviesFeature {

  @ObservableState
  struct State: Equatable {
    var actor: Actor
    @SharedReader var movies: MovieCollection
    var isSearchFieldPresented = false
    var titleSort: Ordering
    var searchText: String = ""

    init(actor: Actor, titleSort: Ordering = .forward) {
      self.actor = actor
      self.titleSort = titleSort
      _movies = SharedReader(
        .fetch(
          ActorMoviesQuery(actor: actor, ordering: titleSort.sortOrder),
          animation: .smooth
        )
      )
    }
  }

  enum Action {
    case detailButtonTapped(Movie)
    case favoriteSwiped(Movie)
    case searchButtonTapped(Bool)
    case refresh
    case searchTextChanged(String)
    case titleSortChanged(Ordering)
    case toggleFavoriteState(Movie)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .detailButtonTapped: return .none

      case .favoriteSwiped(let movie):
#if os(iOS)
        return Utils.beginFavoriteChange(.toggleFavoriteState(movie))
#endif
#if os(macOS)
        return Utils.toggleFavoriteState(movie)
#endif

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

      case .titleSortChanged(let newSort): return setTitleSort(newSort, state: &state)

      case .toggleFavoriteState(let movie):
        return Utils.toggleFavoriteState(movie)
      }
    }
  }
}

extension ActorMoviesFeature {

  private func refresh(_ state: inout State) -> Effect<Action> {
    @Dependency(\.defaultDatabase) var database
    if let actor = database.actor(id: state.actor.id) {
      state.actor = actor
    }
    return .none
  }

  private func setTitleSort(_ newSort: Ordering, state: inout State) -> Effect<Action> {
    state.titleSort = newSort
    return updateQuery(state)
  }

  private func updateQuery(_ state: State) -> Effect<Action> {
    let searchText = state.searchText.isEmpty ? nil : state.searchText
    let titleSort = state.titleSort
    let actor = state.actor
    let movies = state.$movies
    return .run { _ in
      do {
        try await movies.load(
          .fetch(
            ActorMoviesQuery(actor: actor, ordering: titleSort.sortOrder, searchText: searchText),
            animation: .smooth
          )
        )
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
