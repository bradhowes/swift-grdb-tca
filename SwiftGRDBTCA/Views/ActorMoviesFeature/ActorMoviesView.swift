import ComposableArchitecture
import Dependencies
import GRDB
import Models
import SwiftUI

struct ActorMoviesView: View {
  @Bindable var store: StoreOf<ActorMoviesFeature>

  var body: some View {
    MoviesListView(store: store)
      .navigationTitle(store.actor.name)
#if os(iOS)
      .toolbar(.hidden, for: .tabBar)
#endif
      .toolbar {
        ToolbarItemGroup(placement: .automatic) {
          Utils.pickerView(title: "movie ordering", binding: $store.titleSort.sending(\.titleSortChanged).animation())
        }
      }
      .labelsHidden()
      .task { await store.send(.refresh).finish() }
  }
}

private struct MoviesListView: View {
  var store: StoreOf<ActorMoviesFeature>
  @Dependency(\.defaultDatabase) var database

  var body: some View {
    List(store.movies, id: \.id) { movie in
      MovieListRow(store: store, movie: movie, actorNames: database.actors(for: movie).csv)
#if os(iOS)
        .swipeActions(allowsFullSwipe: false) {
          Utils.favoriteMovieButton(movie) {
            store.send(.favoriteSwiped(movie), animation: .bouncy)
          }
        }
#endif
    }
  }
}

private struct MovieListRow: View {
  var store: StoreOf<ActorMoviesFeature>
  let movie: Movie
  let actorNames: String

#if os(iOS)
  var body: some View {
    detailButton
  }
#endif

#if os(macOS)
  var body: some View {
    HStack {
      detailButton
      Utils.favoriteMovieButton(movie) {
        store.send(.favoriteSwiped(movie), animation: .bouncy)
      }
    }
  }
#endif

  private var detailButton: some View {
    Button {
      _ = store.send(.detailButtonTapped(movie))
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

extension MoviesListView {

  func withSwipeActions<T>(movie: Movie, @ViewBuilder content: () -> T) -> some View where T: View {
    content()
      .swipeActions {
        Utils.favoriteMovieButton(movie) {
          store.send(.favoriteSwiped(movie), animation: .bouncy)
        }
      }
  }
}

extension ActorMoviesView {
  static var preview: some View {
    let _ = prepareDependencies { // swiftlint:disable:this redundant_discardable_let
      $0.defaultDatabase = try! DatabaseQueue.appDatabase(mockCount: 13) // swiftlint:disable:this force_try
    }
    @Dependency(\.defaultDatabase) var queue
    let movies = queue.movies()
    let actors = queue.actors(for: movies[0])
    return NavigationView {
      ActorMoviesView(store: Store(initialState: .init(actor: actors[1])) {
        ActorMoviesFeature()
      })
    }
#if os(iOS)
    .navigationViewStyle(.stack)
#endif
  }
}

#Preview {
  ActorMoviesView.preview
}
