import ComposableArchitecture
import Dependencies
import GRDB
import Models
import SwiftData
import SwiftUI

struct FromStateView: View {
  @Bindable var store: StoreOf<FromStateFeature>

  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      MovieListView(store: store)
        .navigationTitle("Movies")
        .searchable(
          text: $store.searchText.sending(\.searchTextChanged),
          isPresented: $store.isSearchFieldPresented.sending(\.searchButtonTapped),
          prompt: "Title"
        )
        .toolbar {
          if !store.isSearchFieldPresented {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
              Button("add", systemImage: "plus") { store.send(.addButtonTapped) }
              Utils.pickerView(title: "movie ordering", binding: $store.titleSort.sending(\.titleSortChanged).animation())
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
  var store: StoreOf<FromStateFeature>

  var body: some View {
    ScrollViewReader { proxy in
      List(store.allMovies, id: \.id) { movie in
        if store.searchText.isEmpty || movie.title.localizedCaseInsensitiveContains(store.searchText) {
          MovieListRow(store: store, movie: movie)
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
      .onChange(of: store.scrollTo) { _, movie in
        if let movie {
          withAnimation {
            proxy.scrollTo(movie.id)
          }
          store.send(.clearScrollTo)
        }
      }
    }
  }
}

private struct MovieListRow: View {
  var store: StoreOf<FromStateFeature>
  let movie: Movie
  let actorNames: String
  @Dependency(\.viewLinkType) var viewLinkType

  init(store: StoreOf<FromStateFeature>, movie: Movie) {
    self.store = store
    self.movie = movie
    // Fetch the actor names while we know that the Movie is valid.
    @Dependency(\.defaultDatabase) var database
    do {
      let actors = try database.read { db in
        try movie.actors.order(Actor.Columns.name.asc).fetchAll(db)
      }
      actorNames = actors.map(\.name).joined(separator: ", ")
    } catch {
      fatalError("failed to fetch actors of movie \(movie.title): \(error)")
    }
  }

  var body: some View {
    if viewLinkType == .navLink {
      RootFeature.link(movie)
        .fadeIn(enabled: store.highlight == movie, duration: 1.25) {
          store.send(.clearHighlight)
        }
    } else {
      detailButton
        .fadeIn(enabled: store.highlight == movie, duration: 1.25) {
          store.send(.clearHighlight)
        }
    }
  }

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

extension FromStateView {
  static var previewWithButtons: some View {
    let _ = prepareDependencies { // swiftlint:disable:this redundant_discardable_let
      $0.defaultDatabase = try! DatabaseQueue.appDatabase(mockCount: 5) // swiftlint:disable:this force_try
      $0.viewLinkType = .button
    }
    let store = Store(initialState: .init()) { FromStateFeature() }
    return FromStateView(store: store)
  }
}

#Preview {
  FromStateView.previewWithButtons
}
