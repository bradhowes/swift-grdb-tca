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
        Utils.ActorView(name: actor.name, movieTitles: database.movies(for: actor).csv)
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
              .transition(.confetti(color: Utils.favoriteColor, size: 3, enabled: store.animateButton))
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
    let _ = prepareDependencies { // swiftlint:disable:this redundant_discardable_let
      $0.defaultDatabase = try! DatabaseQueue.appDatabase(rowCount: 13) // swiftlint:disable:this force_try
    }
    @Dependency(\.defaultDatabase) var queue
    let movies = queue.movies()
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
