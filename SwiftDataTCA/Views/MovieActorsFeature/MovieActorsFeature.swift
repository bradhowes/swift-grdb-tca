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

    var actors: [Actor] {
      switch nameSort {
      case .forward:
        return movie.actors.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }

      case .reverse:
        return movie.actors.sorted { $0.name.localizedCompare($1.name) == .orderedDescending }

      case nil:
        return movie.actors
      }
    }
  }

  enum Action: Sendable {
    case actorSelected(Actor)
    case nameSortChanged(SortOrder?)
    case favoriteTapped
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .actorSelected:
        // NOTE: this is handled by the root feature
        return .none

      case .nameSortChanged(let newSort):
        state.nameSort = newSort
        return .none

      case .favoriteTapped:
        state.movie.favorite.toggle()
        return .none
      }
    }
  }
}

#Preview {
  MovieActorsView.preview
}
