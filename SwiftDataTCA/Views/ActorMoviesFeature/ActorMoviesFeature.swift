import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI

@Reducer
struct ActorMoviesFeature {

  @ObservableState
  struct State: Equatable {
    let actor: Actor
    let useLinks: Bool
    var titleSort: SortOrder?
    var movies: [Movie]
    var selectedMovie: Movie?

    init(actor: Actor, useLinks: Bool = false, titleSort: SortOrder? = .forward) {
      print("ActorMoviesFeature.init - \(actor.name)")
      self.actor = actor
      self.useLinks = useLinks
      self.titleSort = titleSort
      self.movies = actor.movies(ordering: titleSort)
    }
  }

  enum Action: Sendable {
    case detailButtonTapped(Movie)
    case favoriteSwiped(Movie)
    case refresh
    case titleSortChanged(SortOrder?)
    case toggleFavoriteState(Movie)
  }

  @Dependency(\.continuousClock) var clock

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .detailButtonTapped: return .none
      case .favoriteSwiped(let movie): return Utils.beginFavoriteChange(.toggleFavoriteState(movie))
      case .refresh: return refresh(state: &state)
      case .titleSortChanged(let newSort): return setTitleSort(newSort, state: &state)
      case .toggleFavoriteState(let movie): return Utils.toggleFavoriteState(movie, movies: &state.movies)
      }
    }
  }
}

extension ActorMoviesFeature {

  private func refresh(state: inout State) -> Effect<Action> {
    state.movies = state.actor.movies(ordering: state.titleSort)
    return .none
  }

  private func setTitleSort(_ newSort: SortOrder?, state: inout State) -> Effect<Action> {
    state.titleSort = newSort
    state.movies = state.actor.movies(ordering: newSort)
    return .none
  }
}

#Preview {
  ActorMoviesView.previewWithoutLinks
}
