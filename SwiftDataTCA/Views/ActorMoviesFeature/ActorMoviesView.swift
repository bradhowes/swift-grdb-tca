import ComposableArchitecture
import Dependencies
import SwiftData
import SwiftUI

struct ActorMoviesView: View {
  @Bindable var store: StoreOf<ActorMoviesFeature>

  var body: some View {
    MoviesListView(store: store)
      .navigationTitle(store.actor.name)
      .toolbar(.hidden, for: .tabBar)
      .toolbar {
        ToolbarItemGroup(placement: .automatic) {
          Utils.pickerView(title: "Title", binding: $store.titleSort.sending(\.titleSortChanged).animation())
        }
      }
      .labelsHidden()
  }
}

private struct MoviesListView: View {
  @Bindable var store: StoreOf<ActorMoviesFeature>

  var body: some View {
    List(store.movies, id: \.modelId) { movie in
      NavigationLink(state: RootFeature.showMovieActors(movie)) {
        Utils.MovieView(movie: movie)
          .swipeActions { favoriteSwipAction(for: movie) }
      }
    }.onAppear {
      store.send(.refresh)
    }
  }

  private func favoriteSwipAction(for movie: Movie) -> some View {
    Utils.favoriteSwipeAction(movie) {
      store.send(.favoriteSwiped(movie), animation: .bouncy)
    }
  }
}

extension ActorMoviesView {
  static var preview: some View {
    @Dependency(\.modelContextProvider) var context
    let actorModel = ActiveSchema.fetchOrMakeActor(context, name: "Marlon Brando")
    let movies = Support.sortedMovies(for: actorModel, order: .forward)
    movies[0].favorite = true
    return NavigationView {
      ActorMoviesView(store: Store(initialState: .init(actor: actorModel.valueType)) { ActorMoviesFeature() })
        .modelContext(context)
    }
  }
}

#Preview {
  ActorMoviesView.preview
}
