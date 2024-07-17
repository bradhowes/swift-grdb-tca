import ComposableArchitecture
import Dependencies
import SwiftData
import SwiftUI

struct FromStateView: View {
  @Bindable var store: StoreOf<FromStateFeature>

  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      MovieListView(store: store)
        .navigationTitle("From State")
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
    .onAppear {
      store.send(.onAppear)
    }
  }
}

private struct MovieListView: View {
  @Bindable var store: StoreOf<FromStateFeature>
  @State private var selectedMovie: Movie?

  var body: some View {
    List(store.movies, id: \.self, selection: $selectedMovie) { movie in
      Utils.MovieView(movie: movie)
        .swipeActions {
          Button(role: .destructive) {
            store.send(.deleteSwiped(movie), animation: .snappy)
          } label: {
            Label("Delete", systemImage: "trash")
          }
          Button {
            store.send(.favoriteSwiped(movie), animation: .bouncy)
          } label: {
            Label(movie.favorite ? "Unfavorite" : "Favorite", systemImage: "star")
              .foregroundStyle(.blue)
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

extension FromStateView {
  static var preview: some View {
    @Dependency(\.modelContextProvider.container) var container
    return FromStateView(store: Store(initialState: .init()) { FromStateFeature() })
      .modelContainer(container)
  }
}

#Preview {
  FromStateView.preview
}
