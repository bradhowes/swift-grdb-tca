import ComposableArchitecture
import Dependencies
import SwiftData
import SwiftUI

struct FromStateView: View {
  @Bindable var store: StoreOf<FromStateFeature>

  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      MovieListView(store: $store)
        .navigationTitle("FromState")
        .searchable(
          text: $store.searchText.sending(\.searchTextChanged),
          isPresented: $store.isSearchFieldPresented.sending(\.searchButtonTapped),
          prompt: "Title"
        )
        .toolbar {
          if !store.isSearchFieldPresented {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
              Button("add", systemImage: "plus") { store.send(.addButtonTapped) }
              Utils.pickerView(title: "title ordering", binding: $store.titleSort.sending(\.titleSortChanged).animation())
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
    .onAppear {
      store.send(.onAppear)
    }
  }
}

private struct MovieListView: View {
  @Bindable var store: StoreOf<FromStateFeature>

  init(store: Bindable<StoreOf<FromStateFeature>>) {
    self._store = store
  }

  var body: some View {
    ScrollViewReader { proxy in
      List {
        ForEach(store.movies, id: \.self) { movie in
          MovieListRow(store: $store, movie: movie)
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
            proxy.scrollTo(movie)
            store.send(.clearScrollTo)
          }
        }
      }
    }
  }
}

private struct MovieListRow: View {
  @Bindable var store: StoreOf<FromStateFeature>
  let movie: Movie

  init(store: Bindable<StoreOf<FromStateFeature>>, movie: Movie) {
    self._store = store
    self.movie = movie
  }

  var body: some View {
    if store.useLinks {
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
      Utils.MovieView(movie: movie, showChevron: true)
    }
  }
}

extension FromStateView {
  static var previewWithLinks: some View {
    @Dependency(\.modelContextProvider) var context
    return FromStateView(store: Store(initialState: .init(useLinks: true)) { FromStateFeature() })
      .modelContext(context)
  }
  static var previewWithButtons: some View {
    @Dependency(\.modelContextProvider) var context
    return FromStateView(store: Store(initialState: .init(useLinks: false)) { FromStateFeature() })
      .modelContext(context)
  }
}

#Preview {
  FromStateView.previewWithLinks
}

#Preview {
  FromStateView.previewWithButtons
}
