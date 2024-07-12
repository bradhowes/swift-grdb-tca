import Foundation
import SwiftUI
import ComposableArchitecture
import SwiftData
import Dependencies

struct FromQueryView: View {
  @Bindable var store: StoreOf<FromQueryFeature>

  var body: some View {
    NavigationStack {
      MovieListView(store: $store)
        .navigationTitle("From Query")
        .searchable(text: $store.searchString.sending(\.searchStringChanged),
                    isPresented: $store.isSearchFieldPresented.sending(\.searchButtonTapped),
                    placement: .automatic,
                    prompt: "Title")
        .toolbar {
          if !store.isSearchFieldPresented {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
              Button("Add") { store.send(.addButtonTapped) }
              pickerView(title: "Title", binding: $store.titleSort.sending(\.titleSortChanged).animation())
              pickerView(title: "UUID", binding: $store.uuidSort.sending(\.uuidSortChanged).animation())
            }
          }
        }.labelsHidden()
    }
  }

  private func pickerView(title: String, binding: Binding<SortOrder?>) -> some View {
    Picker(title, selection: binding) {
      Text(title + " ↑").tag(SortOrder?.some(.forward))
      Text(title + " ↓").tag(SortOrder?.some(.reverse))
      Text(title + " ⊝").tag(SortOrder?.none)
    }
    .pickerStyle(.automatic)
  }

  static var preview: some View {
    @Dependency(\.modelContextProvider) var modelContextProvider
    return FromQueryView(store: Store(initialState: .init()) { FromQueryFeature() })
      .modelContainer(modelContextProvider.container())
  }
}

private struct MovieListView: View {
  @Bindable var store: StoreOf<FromQueryFeature>
  @Query var moviesQuery: [Movie]

  init(store: Bindable<Store<FromQueryFeature.State, FromQueryFeature.Action>>) {
    self._store = store
    self._moviesQuery = Query(self.store.fetchDescriptor, animation: .default)
  }

  var body: some View {
    List(moviesQuery) { movie in
      MovieView(movie: movie)
        .swipeActions {
          Button(role: .destructive) {
            store.send(.deleteSwiped(movie), animation: .snappy)
          } label: {
            Label("Delete", systemImage: "trash")
          }
          Button {
            store.send(.favoriteSwiped(movie), animation: .bouncy)
          } label: {
            Label(movie.favorite ? "Unfavorite" : "Favorite", systemImage: "star")
              .foregroundStyle(.blue)
          }
        }
    }
  }
}

private struct MovieView: View {
  let movie: Movie

  var body: some View {
    VStack(alignment: .leading) {
      Text(movie.title)
        .font(.headline)
      Text(movie.id.uuidString)
      Text(movie.cast.formatted(.list(type: .and)))
    }
    .background(movie.favorite ? .blue : .clear)
  }
}

#Preview {
  FromQueryView.preview
}
