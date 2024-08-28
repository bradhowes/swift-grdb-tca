import ComposableArchitecture
import Dependencies
import SwiftData
import SwiftUI

@Reducer
struct RootFeature {

  // NOTE: declared here but not used. Each tab root view has its own StackState
  @Reducer(state: .equatable)
  enum Path {
    case showMovieActors(MovieActorsFeature)
    case showActorMovies(ActorMoviesFeature)
  }

  enum Tab {
    case fromStateFeature
    case fromQueryFeature
  }

  @ObservableState
  struct State: Equatable {
    var activeTab: Tab = .fromStateFeature
  }

  enum Action: Sendable {
    case tabChanged(Tab)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .tabChanged(let tab):
        state.activeTab = tab
        return .none
      }
    }
  }
}

extension RootFeature {

  @MainActor
  static func link(_ movie: Movie) -> some View {
    NavigationLink(state: RootFeature.showMovieActors(movie)) {
      Utils.MovieView(movie: movie, showChevron: false)
    }
  }

  static func showMovieActors(_ movie: Movie) -> Path.State {
    .showMovieActors(.init(movie: movie))
  }

  static func showActorMovies(_ actor: Actor) -> Path.State {
    .showActorMovies(.init(actor: actor))
  }
}
