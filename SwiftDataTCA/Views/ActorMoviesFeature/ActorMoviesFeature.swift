import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI

@Reducer
struct ActorMoviesFeature {

  @ObservableState
  struct State {
    var actor: ActorModel
    var titleSort: SortOrder? = .forward
    var movies: [MovieModel] { Support.sortedMovies(for: actor, order: titleSort) }
  }

  enum Action: Sendable {
    case favoriteSwiped(MovieModel)
    case movieSelected(MovieModel)
    case titleSortChanged(SortOrder?)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .favoriteSwiped(let movie):
        movie.favorite.toggle()
        return .none

      case .movieSelected:
        // NOTE: this is handled by the root feature
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
