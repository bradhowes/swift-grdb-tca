import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI

@Reducer
struct ActorMoviesFeature {

  @ObservableState
  struct State {
    let actor: Actor
    var titleSort: SortOrder? = .forward
    var movies: [Movie] = []

    init(actor: Actor) {
      self.actor = actor
      self.movies = actor.movies(ordering: self.titleSort)
    }
  }

  enum Action: Sendable {
    case favoriteSwiped(Movie)
    case movieSelected(Movie)
    case onAppear
    case titleSortChanged(SortOrder?)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .favoriteSwiped(var changed):
        changed.toggleFavorite()
        for (index, movie) in state.movies.enumerated() where movie.modelId == changed.modelId {
          state.movies[index] = changed
        }
        return .none

      case .movieSelected:
        // NOTE: this is handled by the root feature
        return .none

      case .onAppear:
        state.movies = state.actor.movies(ordering: state.titleSort)
        return .none

      case .titleSortChanged(let newSort):
        state.titleSort = newSort
        return .none
      }
    }
  }
}

#Preview {
  ActorMoviesView.preview
}
