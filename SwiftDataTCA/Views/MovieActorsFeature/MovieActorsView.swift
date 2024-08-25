import ComposableArchitecture
import Dependencies
import SwiftData
import SwiftUI

struct MovieActorsView: View {
  @Bindable var store: StoreOf<MovieActorsFeature>

  var body: some View {
    ActorsListView(actors: store.actors)
      .navigationTitle(store.movie.name)
      .toolbar(.hidden, for: .tabBar)
      .toolbar {
        ToolbarItemGroup(placement: .automatic) {
          Utils.pickerView(title: "Name", binding: $store.nameSort.sending(\.nameSortChanged).animation())
          Button {
            store.send(.favoriteTapped)
          } label: {
            if store.movie.favorite {
              Image(systemName: "star.fill")
                .foregroundStyle(Utils.favoriteColor)
                // .transition(.confetti(color: Utils.favoriteColor, size: 3))
            } else {
              Image(systemName: "star")
            }
          }
        }
      }
      .labelsHidden()
      .onAppear { store.send(.refresh) }
  }
}

private struct ActorsListView: View {
  var actors: [Actor]

  var body: some View {
    List(actors, id: \.modelId) { actor in
      NavigationLink(state: RootFeature.showActorMovies(actor)) {
        Utils.ActorView(actor: actor)
      }
    }
  }
}

extension MovieActorsView {
  static var preview: some View {
    @Dependency(\.modelContextProvider) var context
    let movies = (try? context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward))) ?? []
    let movie = movies[0].valueType
    return NavigationView {
      MovieActorsView(store: Store(initialState: .init(movie: movie)) { MovieActorsFeature() })
        .modelContext(context)
    }.navigationViewStyle(.stack)
  }
}

#Preview {
  MovieActorsView.preview
}
