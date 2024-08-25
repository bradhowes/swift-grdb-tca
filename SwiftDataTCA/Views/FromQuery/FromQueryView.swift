import ComposableArchitecture
import Dependencies
import Foundation
import SwiftData
import SwiftUI

struct FromQueryView: View {
  @Bindable var store: StoreOf<FromQueryFeature>

  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      MovieListView(store: $store)
        .navigationTitle("From Query")
        .searchable(
          text: $store.searchString.sending(\.searchStringChanged),
          isPresented: $store.isSearchFieldPresented.sending(\.searchButtonTapped),
          placement: .automatic,
          prompt: "Title"
        )
        .toolbar {
          if !store.isSearchFieldPresented {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
              Button("Add") { store.send(.addButtonTapped) }
              Utils.pickerView(title: "Title", binding: $store.titleSort.sending(\.titleSortChanged).animation())
            }
          }
        }
        .labelsHidden()
    } destination: { store in
      switch store.case {
      case let .showMovieActors(store):
        MovieActorsView(store: store)

      case let .showActorMovies(store):
        ActorMoviesView(store: store)
      }
    }
  }
}

private struct MovieListView: View {
  @Bindable var store: StoreOf<FromQueryFeature>
  @Query var moviesQuery: [MovieModel]
  var movies: [Movie] { moviesQuery.map { $0.valueType } }
  @State private var selectedMovie: Movie?

  init(store: Bindable<Store<FromQueryFeature.State, FromQueryFeature.Action>>) {
    self._store = store
    self._moviesQuery = Query(self.store.fetchDescriptor, animation: .default)
  }

  var body: some View {
    List(movies, id: \.self, selection: $selectedMovie) { movie in
      NavigationLink(state: RootFeature.showMovieActors(movie)) {
        Utils.MovieView(movie: movie)
      }
      .swipeActions {
        Utils.deleteSwipeAction(movie) {
          store.send(.deleteSwiped(movie), animation: .snappy)
        }
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
  }
}

extension FromQueryView {
  static var preview: some View {
    @Dependency(\.modelContextProvider) var context
    return FromQueryView(store: Store(initialState: .init()) { FromQueryFeature() })
      .modelContext(context)
  }
}

#Preview {
  FromQueryView.preview
}
