import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI

@Reducer
struct MovieActorsFeature {

  @ObservableState
  struct State {
    var movie: Movie
    var nameSort: SortOrder? = .forward
    var actors: [Actor] { movie.actors(ordering: nameSort) }
  }

  enum Action: Sendable {
    case actorSelected(Actor)
    case favoriteTapped
    case nameSortChanged(SortOrder?)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .actorSelected:
        // NOTE: this is handled by the root feature
        return .none

      case .favoriteTapped:
        state.movie.toggleFavorite()
        return .none

      case .nameSortChanged(let newSort):
        state.nameSort = newSort
        return .none
      }
    }
  }
}

#Preview {
  MovieActorsView.preview
}
