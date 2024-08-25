import ComposableArchitecture
import Dependencies
import SwiftData
import SwiftUI

struct FromStateView: View {
  @Bindable var store: StoreOf<FromStateFeature>

  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      MovieListView(store: store)
        .navigationTitle("FromState")
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
      case let .showMovieActors(store): MovieActorsView(store: store)
      case let .showActorMovies(store): ActorMoviesView(store: store)
      }
    }
    .onAppear {
      store.send(.onAppear)
    }
  }
}

private struct MovieListView: View {
  @Bindable var store: StoreOf<FromStateFeature>

  var body: some View {
    List(store.movies, id: \.self) { movie in
      NavigationLink(state: RootFeature.showMovieActors(movie)) {
        Utils.MovieView(movie: movie)
      }
      .swipeActions(allowsFullSwipe: false) {
        Utils.deleteSwipeAction(movie) {
          store.send(.deleteSwiped(movie), animation: .snappy)
        }
        Utils.favoriteSwipeAction(movie) {
          store.send(.favoriteSwiped(movie), animation: .bouncy)
        }
      }
    }
  }
}

extension FromStateView {
  static var preview: some View {
    @Dependency(\.modelContextProvider) var context
    return FromStateView(store: Store(initialState: .init()) { FromStateFeature() })
      .modelContext(context)
  }
}

#Preview {
  FromStateView.preview
}
