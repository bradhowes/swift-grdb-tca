import ComposableArchitecture
import Dependencies
import GRDB
import Models
import SwiftUI

struct RootView: View {
  @Bindable var store: StoreOf<RootFeature>

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
          if !store.isSearchFieldPresented {
            ToolbarItemGroup(placement: .automatic) {
              Button("add", systemImage: "plus") { store.send(.addButtonTapped) }
              Utils.pickerView(title: "movie ordering", binding: $store.titleSort.sending(\.titleSortChanged).animation())
            }
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
#endif
      }
      .onChange(of: store.scrollTo) { _, movie in
        if let movie {
          withAnimation {
            proxy.scrollTo(movie.id)
          }
          store.send(.clearScrollTo)
        }
      }
    }
    .animation(.smooth, value: store.scrollTo)
    .animation(.smooth, value: store.movies)
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
      .fadeIn(enabled: store.highlight == movie, duration: 1.25) {
        store.send(.clearHighlight)
      }
  }
#endif

#if os(macOS)
  var body: some View {
    HStack {
      detailButton
        .fadeIn(enabled: store.highlight == movie, duration: 1.25) {
          store.send(.clearHighlight)
        }
      Utils.favoriteMovieButton(movie) {
        store.send(.favoriteSwiped(movie), animation: .bouncy)
      }
      Utils.deleteMovieButton(movie) {
        store.send(.deleteSwiped(movie), animation: .snappy)
      }
    }
  }
#endif

  private var detailButton: some View {
    Button {
      _ = store.send(.movieButtonTapped(movie))
    } label: {
      Utils.MovieView(
        name: movie.title,
        favorite: movie.favorite,
        actorNames: actorNames,
        showChevron: true
      )
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
