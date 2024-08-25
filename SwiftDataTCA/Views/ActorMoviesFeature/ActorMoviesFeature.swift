import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI

@Reducer
struct ActorMoviesFeature {

  @ObservableState
  struct State: Equatable {
    let actor: Actor
    var titleSort: SortOrder?
    var movies: [Movie]
    var selectedMovie: Movie?

    init(actor: Actor, titleSort: SortOrder? = .forward) {
      print("ActorMoviesFeature.init - \(actor.name)")
      self.actor = actor
      self.titleSort = titleSort
      self.movies = actor.movies(ordering: titleSort)
    }
  }

  enum Action: Sendable {
    case favoriteSwiped(Movie)
    case refresh
    case titleSortChanged(SortOrder?)
    case toggleFavoriteState(Movie)
  }

  @Dependency(\.continuousClock) var clock

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .favoriteSwiped(let movie): return beginFavoriteChange(movie)
      case .refresh: return refresh(state: &state)
      case .titleSortChanged(let newSort): return setTitleSort(newSort, state: &state)
      case .toggleFavoriteState(let movie): return toggleFavoriteState(movie, state: &state)
      }
    }
  }
}

extension ActorMoviesFeature {

  private func beginFavoriteChange(_ movie: Movie) -> Effect<Action> {
    print("ActorMoviesFeature.beginFavoriteChange - \(movie.name)")
    return .run { send in
      try await clock.sleep(for: .milliseconds(800))
      await send(.toggleFavoriteState(movie), animation: .default)
    }
  }

  private func refresh(state: inout State) -> Effect<Action> {
    state.movies = state.actor.movies(ordering: state.titleSort)
    return .none
  }

  private func setTitleSort(_ newSort: SortOrder?, state: inout State) -> Effect<Action> {
    print("ActorMoviesFeature.setTitleSort - \(String(describing: newSort))")
    state.titleSort = newSort
    state.movies = state.actor.movies(ordering: newSort)
    return .none
  }

  private func toggleFavoriteState(_ movie: Movie, state: inout State) -> Effect<Action> {
    print("ActorMoviesFeature.toggleFavoriteState - \(movie)")
    let changed = movie.toggleFavorite()
    for (index, movie) in state.movies.enumerated() where movie.modelId == changed.modelId {
      state.movies[index] = changed
    }
    return .none
  }
}

#Preview {
  ActorMoviesView.preview
}
