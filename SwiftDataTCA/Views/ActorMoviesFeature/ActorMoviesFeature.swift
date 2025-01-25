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
    @SharedReader var movies: IdentifiedArrayOf<Movie>
    var titleSort: SortOrder?

    init(actor: Actor, titleSort: SortOrder? = .forward) {
      self.actor = actor
      self.titleSort = titleSort
      _movies = Self.makeQuery(actor: actor, titleSort: titleSort)
    }

    static func makeQuery(actor: Actor, titleSort: SortOrder?) -> SharedReader<IdentifiedArrayOf<Movie>> {
      SharedReader(.fetch(ActorMoviesQuery(actor: actor, ordering: titleSort)))
    }

    mutating func updateQuery() {
      _movies = Self.makeQuery(actor: actor, titleSort: titleSort)
    }
  }

  enum Action: Sendable {
    case detailButtonTapped(Movie)
    case favoriteSwiped(Movie)
    case refresh
    case titleSortChanged(SortOrder?)
    case toggleFavoriteState(Movie)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .detailButtonTapped: return .none
      case .favoriteSwiped(let movie): return Utils.beginFavoriteChange(.toggleFavoriteState(movie))
      case .refresh: return refresh(state: &state)
      case .titleSortChanged(let newSort): return setTitleSort(newSort, state: &state)

      case .toggleFavoriteState(let movie):
        _ = Utils.toggleFavoriteState(movie)
        return .none
      }
    }
  }
}

extension ActorMoviesFeature {

  private func refresh(state: inout State) -> Effect<Action> {
    state.updateQuery()
    return .none
  }

  private func setTitleSort(_ newSort: SortOrder?, state: inout State) -> Effect<Action> {
    state.titleSort = newSort
    state.updateQuery()
    return .none
  }
}

#Preview {
  ActorMoviesView.preview
}
