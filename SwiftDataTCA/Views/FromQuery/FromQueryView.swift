import ComposableArchitecture
import Dependencies
import Foundation
import SwiftData
import SwiftUI

struct FromQueryView: View {
  @Bindable var store: StoreOf<FromQueryFeature>

  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      MovieListView(store: $store, send: store.useLinks ? nil : store.send)
        .navigationTitle("FromQuery")
        .searchable(
          text: $store.searchText.sending(\.searchTextChanged),
          isPresented: $store.isSearchFieldPresented.sending(\.searchButtonTapped),
          placement: .automatic,
          prompt: "Title"
        )
        .toolbar {
          if !store.isSearchFieldPresented {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
              Button("", systemImage: "plus") { store.send(.addButtonTapped) }
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
  }
}

private struct MovieListView: View {
  @Bindable var store: StoreOf<FromQueryFeature>
  let send: ((FromQueryFeature.Action) -> StoreTask)?
  @Query var moviesQuery: [MovieModel]
  var movies: [Movie] { moviesQuery.map(\.valueType) }

  init(
    store: Bindable<Store<FromQueryFeature.State, FromQueryFeature.Action>>,
    send: ((FromQueryFeature.Action) -> StoreTask)?
  ) {
    self._store = store
    self.send = send
    self._moviesQuery = Query(self.store.fetchDescriptor, animation: .default)
  }

  var body: some View {
    ScrollViewReader { proxy in
      List(movies, id: \.modelId) { movie in
        withSwipeActions(movie: movie) {
          if let send {
            detailButton(movie, send: send)
          } else {
            RootFeature.link(movie)
          }
        }
      }
      .onChange(of: store.scrollTo) { _, movie in
        if let movie {
          withAnimation {
            proxy.scrollTo(movie.modelId)
          }
          store.send(.clearScrollTo)
        }
      }
    }
  }

  private func detailButton(_ movie: Movie, send: @escaping (FromQueryFeature.Action) -> StoreTask) -> some View {
    Button {
      _ = send(.detailButtonTapped(movie))
    } label: {
      Utils.MovieView(movie: movie, showChevron: true)
    }
  }
}

extension MovieListView {

  func withSwipeActions<T>(movie: Movie, @ViewBuilder content: () -> T) -> some View where T: View {
    content()
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
