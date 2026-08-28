import ComposableArchitecture
import Dependencies
import GRDB
import Models
import SwiftUI

struct MovieActorsView: View {
  @Bindable private var store: StoreOf<MovieActorsFeature>
  @Dependency(\.defaultDatabase) private var database

  init(store: StoreOf<MovieActorsFeature>) {
    self.store = store
  }

  var body: some View {
    List(store.actors, id: \.id) { actor in
      Button {
        store.send(.detailButtonTapped(actor))
      } label: {
        Utils.ActorView(name: actor.name, movieTitles: actor.movieTitles)
      }
    }
    .animation(.smooth, value: store.actors)
    .navigationTitle(store.movie.title + " [\(store.actors.count)]")
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
        Utils.pickerView(title: "actor ordering", binding: $store.nameSort.sending(\.nameSortChanged).animation())
        Button {
          store.send(.favoriteTapped)
        } label: {
          if store.movie.favorite {
            Image(systemName: "star.fill")
              .accessibilityLabel("unfavorite movie")
              .foregroundStyle(Utils.favoriteColor)
              .flash(enabled: store.animateButton, count: 3, duration: 0.05)
              // .transition(.confetti(color: Utils.favoriteColor, size: 3, enabled: store.animateButton))
          } else {
            Image(systemName: "star")
              .accessibilityLabel("favorite movie")
          }
        }
      }
    }
    .labelsHidden()
    .onAppear {
      store.send(.refresh)
    }
  }
}

extension MovieActorsView {
  static var preview: some View {
    let movies = prepareDependencies {
      $0.defaultDatabase = try! appDatabase(rowCount: 13) // swiftlint:disable:this force_try
      return try! $0.defaultDatabase.read { // swiftlint:disable:this force_try
        try AllMoviesQuery().fetch($0)
      }
    }
    return NavigationView {
      MovieActorsView(store: Store(initialState: .init(movie: movies[0])) {
        MovieActorsFeature()
      })
    }
#if os(iOS)
    .navigationViewStyle(.stack)
#endif
  }
}

#Preview {
  MovieActorsView.preview
}
