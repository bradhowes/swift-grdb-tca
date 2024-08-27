import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI

@Reducer
struct MovieActorsFeature {

  @ObservableState
  struct State: Equatable {
    var movie: Movie
    let useLinks: Bool
    var nameSort: SortOrder? = .forward
    var actors: [Actor]
    var animateButton = false

    init(movie: Movie, useLinks: Bool = false, nameSort: SortOrder? = .forward) {
      print("MovieActorsFeature.init - \(movie.name)")
      self.movie = movie
      self.useLinks = useLinks
      self.nameSort = nameSort
      self.actors = movie.actors(ordering: nameSort)
    }
  }

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
    state.animateButton = state.movie.favorite
    return .none
  }
}

#Preview {
  MovieActorsView.preview
}
