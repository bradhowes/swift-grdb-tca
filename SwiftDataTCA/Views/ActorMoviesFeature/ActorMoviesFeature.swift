import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI

@Reducer
struct ActorMoviesFeature {

  @ObservableState
  struct State {
    var actor: Actor
    var titleSort: SortOrder? = .forward

    var movies: [Movie] {
      switch titleSort {
      case .forward:
        return actor.movies.sorted { $0.sortableTitle.localizedCompare($1.sortableTitle) == .orderedAscending }

      case .reverse:
        return actor.movies.sorted { $0.sortableTitle.localizedCompare($1.sortableTitle) == .orderedDescending }

      case nil:
        return actor.movies
      }
    }
  }

  enum Action: Sendable {
    case favoriteSwiped(Movie)
    case movieSelected(Movie)
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
