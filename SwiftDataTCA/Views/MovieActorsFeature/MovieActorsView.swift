import ComposableArchitecture
import Dependencies
import SwiftData
import SwiftUI

struct MovieActorsView: View {
  @Bindable var store: StoreOf<MovieActorsFeature>

  var body: some View {
    ActorsListView(store: store)
      .navigationTitle(store.movie.name)
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Utils.pickerView(title: "Name", binding: $store.nameSort.sending(\.nameSortChanged).animation())
          Button("favorite", systemImage: store.movie.favorite ? "star.fill" : "star") {
            store.send(.favoriteTapped)
          }
        }
      }
      .labelsHidden()
  }
}

private struct ActorsListView: View {
  @Bindable var store: StoreOf<MovieActorsFeature>
  @State private var selectedActor: Actor?

  var body: some View {
    List(store.actors, id: \.self, selection: $selectedActor) {
      Utils.ActorView(actor: $0)
    }
    .onChange(of: selectedActor) { _, newValue in
      if let newValue {
        store.send(.actorSelected(newValue), animation: .bouncy)
        selectedActor = nil
      }
    }
    .onAppear {
      store.send(.onAppear)
    }
  }
}

extension MovieActorsView {
  static var preview: some View {
    @Dependency(\.modelContextProvider) var modelContextProvider
    let context = modelContextProvider.context
    Support.generateMocks(context: context, count: 8)
    let movies = (try? context.fetch(ActiveSchema.movieFetchDescriptor(
      titleSort: .forward,
      searchString: "Apoc"
    ))) ?? []
    let movie = movies[0].valueType
    return NavigationView {
      MovieActorsView(store: Store(initialState: .init(movie: movie)) { MovieActorsFeature() })
        .modelContainer(modelContextProvider.container)
    }
  }
}

#Preview {
  MovieActorsView.preview
}
