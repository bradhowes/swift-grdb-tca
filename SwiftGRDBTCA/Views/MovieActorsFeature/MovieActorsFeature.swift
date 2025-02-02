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
    var actors: IdentifiedArrayOf<Actor>
    var animateButton = false
    var nameSort: Ordering

    init(movie: Movie, nameSort: Ordering = .forward) {
      let sort = Ordering.forward
      self.movie = movie
      self.nameSort = sort
      @Dependency(\.defaultDatabase) var database
      actors = database.actors(for: movie, ordering: sort.sortOrder)
    }
  }

  enum Action {
    case detailButtonTapped(Actor)
    case favoriteTapped
    case nameSortChanged(Ordering)
    case refresh
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .detailButtonTapped: return .none
      case .favoriteTapped: return toggleFavoriteState(state: &state)
      case .nameSortChanged(let newSort): return setNameSort(newSort, state: &state)
      case .refresh: return refreshMovie(&state)
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

  private func updateQuery(_ state: inout State) -> Effect<Action> {
    @Dependency(\.defaultDatabase) var database
    state.actors = database.actors(for: state.movie, ordering: state.nameSort.sortOrder)
    return .none.animation(.smooth)
  }

  private func setNameSort(_ newSort: Ordering, state: inout State) -> Effect<Action> {
    state.nameSort = newSort
    return updateQuery(&state)
  }

  func toggleFavoriteState(state: inout State) -> Effect<Action> {
    @Dependency(\.defaultDatabase) var database
    try? database.write { try state.movie.toggleFavorite(in: $0) }
    state.animateButton = true
    return .none
  }
}

#Preview {
  MovieActorsView.preview
}
