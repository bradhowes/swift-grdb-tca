import ComposableArchitecture
import Dependencies
import SwiftData
import SwiftUI

struct MovieActorsView: View {
  @Bindable var store: StoreOf<MovieActorsFeature>

  var body: some View {
    ActorsListView(store: store)
      .navigationTitle(store.movie.title)
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Utils.pickerView(title: "Name", binding: $store.nameSort.sending(\.nameSortChanged).animation())
          Button("", systemImage: store.movie.favorite ? "star.fill" : "star") {
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
  }
}

extension MovieActorsView {
  static var preview: some View {
    @Dependency(\.modelContextProvider) var modelContextProvider
    @Dependency(\.uuid) var uuid
    let context = modelContextProvider.context
    let movie = Movie(id: uuid(), title: "The Godfather")
    context.insert(movie)
    let actor1 = Actor(id: uuid(), name: "Marlon Brando")
    context.insert(actor1)
    let actor2 = Actor(id: uuid(), name: "Al Pacino")
    context.insert(actor2)
    let actor3 = Actor(id: uuid(), name: "James Caan")
    context.insert(actor3)
    let actor4 = Actor(id: uuid(), name: "Robert Duvall")
    context.insert(actor4)
    movie.actors = [actor1, actor2, actor3, actor4]
    actor1.movies = [movie]
    actor2.movies = [movie]
    actor3.movies = [movie]
    actor4.movies = [movie]
    try? context.save()

    return NavigationView {
      MovieActorsView(store: Store(initialState: .init(movie: movie)) { MovieActorsFeature() })
        .modelContainer(modelContextProvider.container)
    }
  }
}

#Preview {
  MovieActorsView.preview
}
