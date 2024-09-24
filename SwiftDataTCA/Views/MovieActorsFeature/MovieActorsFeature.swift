import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI

@Reducer
struct MovieActorsFeature {
  @ObservableState
  struct State: Equatable {
    var movie: Movie
    var nameSort: SortOrder? = .forward
    var actors: IdentifiedArrayOf<Actor>
    var animateButton = false

    init(movie: Movie, nameSort: SortOrder? = .forward) {
      @Dependency(\.modelContextProvider) var modelContext
      self.movie = movie
      self.nameSort = nameSort
      self.actors = movie.actors(ordering: nameSort)
    }
  }

  @Dependency(\.modelContextProvider) var modelContext

  enum Action: Sendable {
    case detailButtonTapped(Actor)
    case favoriteTapped
    case nameSortChanged(SortOrder?)
    case refresh
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .detailButtonTapped: return .none
      case .favoriteTapped: return toggleFavoriteState(state: &state)
      case .nameSortChanged(let newSort): return setTitleSort(newSort, state: &state)
      case .refresh: return refresh(state: &state)
      }
    }
  }
}

extension MovieActorsFeature {

  private func refresh(state: inout State) -> Effect<Action> {
    state.movie = state.movie.backingObject().valueType
    return .none
  }

  private func setTitleSort(_ newSort: SortOrder?, state: inout State) -> Effect<Action> {
    state.nameSort = newSort
    state.actors = state.movie.actors(ordering: newSort)
    return .none
  }

  func toggleFavoriteState(state: inout State) -> Effect<Action> {
    state.movie = state.movie.toggleFavorite()
    state.animateButton = state.movie.favorite
    return .none
  }
}

#Preview {
  MovieActorsView.preview
}
