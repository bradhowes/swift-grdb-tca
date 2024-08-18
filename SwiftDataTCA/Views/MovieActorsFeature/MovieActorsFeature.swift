import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI

@Reducer
struct MovieActorsFeature {

  @ObservableState
  struct State {
    var movie: MovieModel
    var nameSort: SortOrder? = .forward
    var actors: [ActorModel] { Support.sortedActors(for: movie, order: nameSort) }
  }

  enum Action: Sendable {
    case actorSelected(ActorModel)
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
        state.movie.favorite.toggle()
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
