import ComposableArchitecture
import Dependencies
import SwiftData
import SwiftUI

struct FromStateView: View {
  @Bindable var store: StoreOf<FromStateFeature>

  var body: some View {
    NavigationStack {
      MovieListView(store: store)
      .navigationTitle("From State")
      .searchable(
        text: $store.searchString.sending(\.searchStringChanged),
        isPresented: $store.isSearchFieldPresented.sending(\.searchButtonTapped),
        placement: .automatic,
        prompt: "Title"
      )
      .toolbar {
        if !store.isSearchFieldPresented {
          ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button("Add") { store.send(.addButtonTapped) }
            pickerView(title: "Title", binding: $store.titleSort.sending(\.titleSortChanged).animation())
            pickerView(title: "UUID", binding: $store.uuidSort.sending(\.uuidSortChanged).animation())
          }
        }
      }
      .labelsHidden()
    }
    .onAppear {
      store.send(.onAppear)
    }
  }

  private func pickerView(title: String, binding: Binding<SortOrder?>) -> some View {
    Picker(title, selection: binding) {
      Text(title + " ↑").tag(SortOrder?.some(.forward))
      Text(title + " ↓").tag(SortOrder?.some(.reverse))
      Text(title + " ⊝").tag(SortOrder?.none)
    }.pickerStyle(.automatic)
  }

  static var preview: some View {
    @Dependency(\.modelContextProvider) var modelContextProvider
    return FromStateView(store: Store(initialState: .init()) { FromStateFeature() })
      .modelContainer(modelContextProvider.container())
  }
}

private struct MovieListView: View {
  @Bindable var store: StoreOf<FromStateFeature>

  var body: some View {
    List(store.movies) { movie in
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
  FromStateView.preview
}
