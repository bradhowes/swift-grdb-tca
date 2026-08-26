import ComposableArchitecture
import Dependencies
import GRDB
import Models
import SwiftUI

struct RootView: View {
  @Bindable private var store: StoreOf<RootFeature>

  init(store: StoreOf<RootFeature>) {
    self.store = store
  }

  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      MovieListView(store: store)
        .navigationTitle("Movies [\(store.movies.count)]")
        .searchable(
          text: $store.searchText.sending(\.searchTextChanged),
          isPresented: $store.isSearchFieldPresented.sending(\.searchButtonTapped),
          prompt: "Title"
        )
        .toolbar {
          ToolbarItemGroup(placement: .automatic) {
            if !store.isSearchFieldPresented {
              Button("add", systemImage: "plus") { store.send(.addButtonTapped) }
            }
            Utils.pickerView(title: "movie ordering", binding: $store.titleSort.sending(\.titleSortChanged).animation())
          }
        }
        .labelsHidden()
    } destination: {
      switch $0.case {
      case .showMovieActors(let child): MovieActorsView(store: child)
      case .showActorMovies(let child): ActorMoviesView(store: child)
      }
    }
    .animation(.smooth, value: store.path)
  }
}

private struct MovieListView: View {
  var store: StoreOf<RootFeature>
  @Dependency(\.defaultDatabase) var database

  var body: some View {
    ScrollViewReader { proxy in
      List(store.movies, id: \.id) { movie in
        MovieListRow(store: store, movie: movie, actorNames: database.actors(for: movie).csv)
#if os(iOS)
          .swipeActions(allowsFullSwipe: false) {
            Utils.deleteMovieButton(movie) {
              store.send(.deleteSwiped(movie), animation: .snappy)
            }
            Utils.favoriteMovieButton(movie) {
              store.send(.favoriteSwiped(movie), animation: .bouncy)
            }
          }
#endif // os(iOS)
      }
      .onChange(of: store.scrollTo) { _, movie in
        if let movie {
          withAnimation(.smooth) {
            proxy.scrollTo(movie.id, anchor: .center)
          }
        }
      }
      .animation(.smooth, value: store.movies)
    }
  }
}

private struct MovieListRow: View {
  var store: StoreOf<RootFeature>
  let movie: Movie
  let actorNames: String

  init(store: StoreOf<RootFeature>, movie: Movie, actorNames: String) {
    self.store = store
    self.movie = movie
    self.actorNames = actorNames
  }

#if os(iOS)
  var body: some View {
    detailButton
  }
#endif // os(iOS)

#if os(macOS)
  var body: some View {
    HStack {
      detailButton
      Utils.favoriteMovieButton(movie) {
        store.send(.favoriteSwiped(movie), animation: .bouncy)
      }
      Utils.deleteMovieButton(movie) {
        store.send(.deleteSwiped(movie), animation: .snappy)
      }
    }
  }
#endif // os(macOS)

  private var detailButton: some View {
    Button {
      _ = store.send(.movieButtonTapped(movie))
    } label: {
      Utils.MovieView(
        name: movie.title,
        favorite: movie.favorite,
        actorNames: actorNames
      )
    }
    .fadeIn(enabled: store.highlight == movie, duration: 3.0) {
      store.send(.clearHighlight)
    }
  }
}

extension RootView {
  static var previewWithButtons: some View {
    let _ = prepareDependencies { // swiftlint:disable:this redundant_discardable_let
      $0.defaultDatabase = try! DatabaseQueue.appDatabase(rowCount: 5) // swiftlint:disable:this force_try
    }
    let store = Store(initialState: .init()) { RootFeature() }
    return RootView(store: store)
  }
}

#Preview {
  RootView.previewWithButtons
}
