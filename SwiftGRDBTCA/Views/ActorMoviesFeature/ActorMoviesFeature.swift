import Combine
import ComposableArchitecture
import Foundation
import Models
import Sharing
import SwiftUI

@Reducer
struct ActorMoviesFeature {

  @ObservableState
  struct State: Equatable {
    let actor: Actor
    @SharedReader var movies: MovieCollection
    var titleSort: Ordering

    init(actor: Actor) {
      let sort = Ordering.forward
      self.titleSort = sort
      self.actor = actor
      _movies = SharedReader(
        .fetch(
          ActorMoviesQuery(actor: actor, ordering: sort.sortOrder),
          animation: .smooth
        )
      )
    }
  }

  enum Action {
    case detailButtonTapped(Movie)
    case favoriteSwiped(Movie)
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

      case .titleSortChanged(let newSort): return setTitleSort(newSort, state: &state)

      case .toggleFavoriteState(let movie):
        _ = Utils.toggleFavoriteState(movie)
        return .none.animation(.smooth)
      }
    }
  }
}

extension ActorMoviesFeature {

  private func updateQuery(_ state: State) -> Effect<Action> {
    @Dependency(\.defaultDatabase) var database
    let titleSort = state.titleSort
    let actor = state.actor
    let movies = state.$movies
    return .run { _ in
      do {
        try await movies.load(
          .fetch(
            ActorMoviesQuery(actor: actor, ordering: titleSort.sortOrder),
            animation: .smooth
          )
        )
      } catch {
        reportIssue(error)
      }
    }
    .cancellable(id: "FromStateFeature.updateQuery", cancelInFlight: true)
  }

  private func setTitleSort(_ newSort: Ordering, state: inout State) -> Effect<Action> {
    state.titleSort = newSort
    return updateQuery(state)
  }
}

#Preview {
  ActorMoviesView.preview
}
