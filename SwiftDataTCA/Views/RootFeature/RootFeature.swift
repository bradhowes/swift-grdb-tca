import ComposableArchitecture
import Dependencies
import Models
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

  @ObservableState
  struct State: Equatable {
    var fromState: FromStateFeature.State = .init()
  }

  enum Action: Sendable {
    case fromState(FromStateFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Scope(state: \.fromState, action: \.fromState) { FromStateFeature() }
  }
}

extension RootFeature {

  @MainActor
  static func link(_ movie: Movie) -> some View {
    NavigationLink(state: RootFeature.showMovieActors(movie)) {
      // Fetch the actor names while we know that the Movie is valid.
      Utils.MovieView(
        name: movie.title,
        favorite: movie.favorite,
        actorNames: Utils.actorNamesList(for: movie),
        showChevron: false
      )
    }
  }

  static func showMovieActors(_ movie: Movie) -> Path.State {
    .showMovieActors(.init(movie: movie))
  }

  static func showActorMovies(_ actor: Actor) -> Path.State {
    .showActorMovies(.init(actor: actor))
  }
}

#Preview {
  RootFeatureView.preview
}
