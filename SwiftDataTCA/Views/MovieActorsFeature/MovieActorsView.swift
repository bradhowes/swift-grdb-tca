import ComposableArchitecture
import Dependencies
import GRDB
import Models
import SwiftUI

struct MovieActorsView: View {
  @Bindable var store: StoreOf<MovieActorsFeature>

  var body: some View {
    ActorsListView(store: store)
      .navigationTitle(store.movie.title)
      .toolbar(.hidden, for: .tabBar)
      .toolbar {
        ToolbarItemGroup(placement: .automatic) {
          Utils.pickerView(title: "actor ordering", binding: $store.nameSort.sending(\.nameSortChanged).animation())
          favoriteButton
        }
      }
      .labelsHidden()
  }

  private var favoriteButton: some View {
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

private struct ActorsListView: View {
  @Bindable var store: StoreOf<MovieActorsFeature>
  @Dependency(\.viewLinkType) var viewLinkType
  @Dependency(\.defaultDatabase) var database

  var body: some View {
    List(store.actors, id: \.id) { actor in
      if viewLinkType == .navLink {
        NavigationLink(state: RootFeature.showActorMovies(actor)) {
          Utils.ActorView(name: actor.name, movieTitles: database.movies(for: actor).csv, showChevron: false)
        }
      } else {
        Button {
          store.send(.detailButtonTapped(actor))
        } label: {
          Utils.ActorView(name: actor.name, movieTitles: database.movies(for: actor).csv, showChevron: true)
        }
      }
    }
  }
}

extension MovieActorsView {
  static var preview: some View {
    let _ = prepareDependencies { // swiftlint:disable:this redundant_discardable_let
      $0.defaultDatabase = try! DatabaseQueue.appDatabase(mockCount: 13) // swiftlint:disable:this force_try
      $0.viewLinkType = .button
    }
    @Dependency(\.defaultDatabase) var queue
    let movies = queue.movies()
    return NavigationView {
      MovieActorsView(store: Store(initialState: .init(movie: movies[0])) {
        MovieActorsFeature()
      })
    }.navigationViewStyle(.stack)
  }
}

#Preview {
  MovieActorsView.preview
}
