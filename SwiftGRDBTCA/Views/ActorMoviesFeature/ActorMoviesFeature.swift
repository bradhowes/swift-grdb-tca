import ComposableArchitecture
import Foundation
import IdentifiedCollections
import Models
import SwiftUI

@Reducer
struct ActorMoviesFeature {

  @ObservableState
  struct State: Equatable {
    let actor: Actor
    var movies: IdentifiedArrayOf<Movie>
    var titleSort: Ordering

    init(actor: Actor) {
      let sort = Ordering.forward
      self.titleSort = sort
      self.actor = actor
      @Dependency(\.defaultDatabase) var database
      movies = database.movies(for: actor, ordering: sort.sortOrder)
    }
  }

  enum Action {
    case detailButtonTapped(Movie)
    case favoriteSwiped(Movie)
    case refresh
    case titleSortChanged(Ordering)
    case toggleFavoriteState(Movie)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .detailButtonTapped: return .none

      case .favoriteSwiped(let movie):
#if os(iOS)
        return Utils.beginFavoriteChange(.toggleFavoriteState(movie))
#endif
#if os(macOS)
        return Utils.toggleFavoriteState(movie)
#endif

      case .refresh: return updateQuery(&state)
      case .titleSortChanged(let newSort): return setTitleSort(newSort, state: &state)

      case .toggleFavoriteState(let movie):
        let changed = Utils.toggleFavoriteState(movie)
        if let index = state.movies.index(id: movie.id) {
          state.movies[index] = changed
        }
        return .none.animation(.smooth)
      }
    }
  }
}

extension ActorMoviesFeature {

  private func updateQuery(_ state: inout State) -> Effect<Action> {
    @Dependency(\.defaultDatabase) var database
    state.movies = database.movies(for: state.actor, ordering: state.titleSort.sortOrder)
    return .none.animation(.smooth)
  }

  private func setTitleSort(_ newSort: Ordering, state: inout State) -> Effect<Action> {
    state.titleSort = newSort
    return updateQuery(&state)
  }
}

#Preview {
  ActorMoviesView.preview
}
