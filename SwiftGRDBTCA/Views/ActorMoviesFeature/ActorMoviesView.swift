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
      .toolbar(.hidden, for: .tabBar)
      .toolbar {
        ToolbarItemGroup(placement: .automatic) {
          Utils.pickerView(title: "movie ordering", binding: $store.titleSort.sending(\.titleSortChanged).animation())
        }
      }
      .labelsHidden()
  }
}

private struct MoviesListView: View {
  var store: StoreOf<ActorMoviesFeature>
  @Dependency(\.defaultDatabase) var database

  var body: some View {
    List(store.movies, id: \.id) { movie in
      withSwipeActions(movie: movie) {
        Button {
          _ = store.send(.detailButtonTapped(movie))
        } label: {
          Utils.MovieView(
            name: movie.title,
            favorite: movie.favorite,
            actorNames: database.actors(for: movie).csv,
            showChevron: true
          )
        }
      }
    }
  }
}

extension MoviesListView {

  func withSwipeActions<T>(movie: Movie, @ViewBuilder content: () -> T) -> some View where T: View {
    content()
      .swipeActions {
        Utils.favoriteSwipeAction(movie) {
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
    }.navigationViewStyle(.stack)
  }
}

#Preview {
  ActorMoviesView.preview
}
