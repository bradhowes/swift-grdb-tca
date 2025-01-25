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
    @Shared(.appStorage("titleSort")) var titleSort: Ordering = .forward
    @SharedReader var movies: IdentifiedArrayOf<Movie>

    init(actor: Actor) {
      self.actor = actor
      _movies = .init(
        .fetch(
          ActorMoviesQuery(actor: actor, ordering: _titleSort.wrappedValue.sortOrder),
          animation: .smooth
        )
      )
    }
  }

  enum Action: Sendable {
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
      case .favoriteSwiped(let movie): return Utils.beginFavoriteChange(.toggleFavoriteState(movie))
      case .refresh: return updateQuery(state)
      case .titleSortChanged(let newSort): return setTitleSort(newSort, state: &state)
      case .toggleFavoriteState(let movie): return Utils.toggleFavoriteState(movie)
      }
    }
  }
}

extension ActorMoviesFeature {

  private func updateQuery(_ state: State) -> Effect<Action> {
    let titleSort = state.titleSort
    return .run { _ in
      do {
        try await state.$movies.load(
          .fetch(
            ActorMoviesQuery(actor: state.actor, ordering: titleSort.sortOrder),
            animation: .smooth
          )
        )
      } catch {
        reportIssue(error)
      }
    }
    .cancellable(id: "ActorMoviesFeature.updateQuery")
  }

  private func setTitleSort(_ newSort: Ordering, state: inout State) -> Effect<Action> {
    state.$titleSort.withLock { $0 = newSort }
    return updateQuery(state)
  }
}

#Preview {
  ActorMoviesView.preview
}
