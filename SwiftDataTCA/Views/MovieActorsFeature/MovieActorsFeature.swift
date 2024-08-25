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
    var actors: [Actor]

    init(movie: Movie, nameSort: SortOrder? = .forward) {
      print("MovieActorsFeature.init - \(movie.name)")
      self.movie = movie
      self.nameSort = nameSort
      self.actors = movie.actors(ordering: nameSort)
    }
  }

  enum Action: Sendable {
    case favoriteTapped
    case nameSortChanged(SortOrder?)
    case refresh
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .favoriteTapped: return toggleFavoriteState(state: &state)
      case .nameSortChanged(let newSort): return setTitleSort(newSort, state: &state)
      case .refresh: return refresh(state: &state)
      }
    }
  }
}

extension MovieActorsFeature {

  private func refresh(state: inout State) -> Effect<Action> {
    print("MovieActorFeature.refreshState - \(state.movie.name)")
    state.movie = state.movie.backingObject().valueType
    return .none
  }

  private func setTitleSort(_ newSort: SortOrder?, state: inout State) -> Effect<Action> {
    print("MovieActorFeature.setTitleSort - \(String(describing: newSort))")
    state.nameSort = newSort
    state.actors = state.movie.actors(ordering: newSort)
    return .none
  }

  func toggleFavoriteState(state: inout State) -> Effect<Action> {
    print("MovieActorFeature.favoriteTapped - \(state.movie.name)")
    state.movie = state.movie.toggleFavorite()
    return .none
  }
}

#Preview {
  MovieActorsView.preview
}
