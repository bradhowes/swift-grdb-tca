import ComposableArchitecture
import Dependencies
import GRDB
import Models
import SwiftUI

struct ActorMoviesView: View {
  @Bindable private var store: StoreOf<ActorMoviesFeature>
  @Dependency(\.defaultDatabase) private var database

  init(store: StoreOf<ActorMoviesFeature>) {
    self.store = store
  }

  var body: some View {
    List(store.movies, id: \.id) { movie in
#if os(iOS)
      Button {
        _ = store.send(.detailButtonTapped(movie))
      } label: {
        Utils.MovieView(
          name: movie.title,
          favorite: movie.favorite,
          actorNames: database.actors(for: movie).csv
        )
      }
      .swipeActions(allowsFullSwipe: false) {
        Utils.favoriteMovieButton(movie) {
          store.send(.favoriteSwiped(movie), animation: .bouncy)
        }
      }
#endif
#if os(macOS)
      HStack {
        Button {
          _ = store.send(.detailButtonTapped(movie))
        } label: {
          Utils.MovieView(
            name: movie.title,
            favorite: movie.favorite,
            actorNames: database.actors(for: movie).csv
          )
        }
        Utils.favoriteMovieButton(movie) {
          store.send(.favoriteSwiped(movie), animation: .bouncy)
        }
      }
#endif
    }
    .animation(.smooth, value: store.movies)
      .navigationTitle(store.actor.name + " [\(store.movies.count)]")
#if os(iOS)
      .toolbar(.hidden, for: .tabBar)
#endif
      .searchable(
        text: $store.searchText.sending(\.searchTextChanged),
        isPresented: $store.isSearchFieldPresented.sending(\.searchButtonTapped),
        prompt: "Title"
      )
      .toolbar {
        ToolbarItemGroup(placement: .automatic) {
          Utils.pickerView(title: "movie ordering", binding: $store.titleSort.sending(\.titleSortChanged).animation())
        }
      }
      .labelsHidden()
      .onAppear {
        store.send(.refresh)
      }
  }
}

extension ActorMoviesView {
  static var preview: some View {
    let _ = prepareDependencies { // swiftlint:disable:this redundant_discardable_let
      $0.defaultDatabase = try! DatabaseQueue.appDatabase(rowCount: 13) // swiftlint:disable:this force_try
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
