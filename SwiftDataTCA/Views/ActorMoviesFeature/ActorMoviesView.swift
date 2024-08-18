import ComposableArchitecture
import Dependencies
import SwiftData
import SwiftUI

struct ActorMoviesView: View {
  @Bindable var store: StoreOf<ActorMoviesFeature>

  var body: some View {
    MoviesListView(store: store)
      .navigationTitle(store.actor.name)
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Utils.pickerView(title: "Title", binding: $store.titleSort.sending(\.titleSortChanged).animation())
        }
      }
      .labelsHidden()
  }
}

private struct MoviesListView: View {
  @Bindable var store: StoreOf<ActorMoviesFeature>
  @State private var selectedMovie: Movie?

  var body: some View {
    List(store.movies, id: \.self, selection: $selectedMovie) { movie in
      Utils.MovieView(movie: movie)
        .swipeActions {
          Utils.favoriteSwipeAction(movie) {
            store.send(.favoriteSwiped(movie), animation: .bouncy)
          }
        }
    }
    .onChange(of: selectedMovie) { _, newValue in
      if let newValue {
        store.send(.movieSelected(newValue), animation: .bouncy)
        selectedMovie = nil
      }
    }
    .onAppear {
      store.send(.onAppear)
    }
  }
}

extension ActorMoviesView {
  static var preview: some View {
    @Dependency(\.modelContextProvider) var modelContextProvider
    Support.generateMocks(context: modelContextProvider.context, count: 8)
    let actorModel = ActiveSchema.fetchOrMakeActor(modelContextProvider.context, name: "Marlon Brando")
    let movies = Support.sortedMovies(for: actorModel, order: .forward)
    movies[1].favorite = true
    movies[3].favorite = true
    return NavigationView {
      ActorMoviesView(store: Store(initialState: .init(actor: actorModel.valueType)) { ActorMoviesFeature() })
        .modelContainer(modelContextProvider.container)
    }
  }
}

#Preview {
  ActorMoviesView.preview
}
