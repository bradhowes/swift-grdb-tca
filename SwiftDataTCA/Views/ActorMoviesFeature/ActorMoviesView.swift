import ComposableArchitecture
import Dependencies
import SwiftData
import SwiftUI

struct ActorMoviesView: View {
  @Bindable var store: StoreOf<ActorMoviesFeature>

  var body: some View {
    MoviesListView(store: store)
      .navigationTitle("\(store.actor.name) - Movies")
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Utils.pickerView(title: "Title", binding: $store.titleSort.sending(\.titleSortChanged).animation())
        }
      }
      .labelsHidden()
  }
}

private struct MoviesListView: View {
  @Bindable var store: StoreOf<ActorMoviesFeature>
  @State private var selectedMovie: Movie?

  var body: some View {
    List(store.movies, id: \.self, selection: $selectedMovie) {
      Utils.MovieView(movie: $0)
    }
    .onChange(of: selectedMovie) { _, newValue in
      if let newValue {
        store.send(.movieSelected(newValue), animation: .bouncy)
        selectedMovie = nil
      }
    }
  }
}

extension ActorMoviesView {
  static var preview: some View {
    @Dependency(\.modelContextProvider) var modelContextProvider
    @Dependency(\.uuid) var uuid
    let context = modelContextProvider.context
    let actor = Actor(id: uuid(), name: "Marlon Brando")
    context.insert(actor)
    let movie1 = Movie(id: uuid(), title: "The Godfather")
    context.insert(movie1)
    let movie2 = Movie(id: uuid(), title: "Last Tango in Paris")
    context.insert(movie2)
    let movie3 = Movie(id: uuid(), title: "On the Waterfront")
    context.insert(movie3)
    let movie4 = Movie(id: uuid(), title: "A Streetcar Named Desire")
    context.insert(movie4)
    let movie5 = Movie(id: uuid(), title: "Apocalypse Now")
    context.insert(movie5)

    actor.movies = [movie1, movie2, movie3, movie4, movie5]
    movie1.actors = [actor]
    movie2.actors = [actor]
    movie3.actors = [actor]
    movie4.actors = [actor]

    try? context.save()

    return ActorMoviesView(store: Store(initialState: .init(actor: actor)) { ActorMoviesFeature() })
      .modelContainer(modelContextProvider.container)
  }
}

#Preview {
  ActorMoviesView.preview
}
