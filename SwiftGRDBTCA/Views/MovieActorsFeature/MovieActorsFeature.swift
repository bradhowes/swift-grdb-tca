import ComposableArchitecture
import Dependencies
import Foundation
import IdentifiedCollections
import Models
import SharedGRDB
import SwiftUI

@Reducer
struct MovieActorsFeature {

  @ObservableState
  struct State: Equatable {
    var movie: Movie
    @SharedReader var actors: ActorCollection
    var isSearchFieldPresented = false
    var animateButton = false
    var nameSort: Ordering
    var searchText: String = ""

    init(movie: Movie, nameSort: Ordering = .forward) {
      self.movie = movie
      self.nameSort = nameSort
      _actors = SharedReader(
        .fetch(
          MovieActorsQuery(movie: movie, ordering: nameSort.sortOrder),
          animation: .smooth
        )
      )
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
      case .favoriteTapped: return toggleFavoriteState(state: &state)
      case .nameSortChanged(let newSort): return setNameSort(newSort, state: &state)
      case .refresh: return refreshMovie(&state)

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

  private func refreshMovie(_ state: inout State) -> Effect<Action> {
    @Dependency(\.defaultDatabase) var database
    if let movie = database.movie(id: state.movie.id) {
      state.movie = movie
    }
    return .none
  }

  private func setNameSort(_ newSort: Ordering, state: inout State) -> Effect<Action> {
    state.nameSort = newSort
    return updateQuery(state)
  }

  func toggleFavoriteState(state: inout State) -> Effect<Action> {
    @Dependency(\.defaultDatabase) var database
    try? database.write { try state.movie.toggleFavorite(in: $0) }
    state.animateButton = true
    return .none
  }

  private func updateQuery(_ state: State) -> Effect<Action> {
    let searchText = state.searchText.isEmpty ? nil : state.searchText
    let nameSort = state.nameSort
    let movie = state.movie
    let actors = state.$actors
    return .run { _ in
      do {
        try await actors.load(
          .fetch(
            MovieActorsQuery(movie: movie, ordering: nameSort.sortOrder, searchText: searchText),
            animation: .smooth
          )
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
