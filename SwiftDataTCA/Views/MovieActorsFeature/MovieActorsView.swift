import ComposableArchitecture
import Dependencies
import SwiftData
import SwiftUI

struct MovieActorsView: View {
  @Bindable var store: StoreOf<MovieActorsFeature>

  var body: some View {
    ActorsListView(actors: store.actors, send: store.send)
      .navigationTitle(store.movie.name)
      .toolbar(.hidden, for: .tabBar)
      .toolbar {
        ToolbarItemGroup(placement: .automatic) {
          Utils.pickerView(title: "Name", binding: $store.nameSort.sending(\.nameSortChanged).animation())
          favoriteButton
        }
      }
      .labelsHidden()
      .onAppear { store.send(.refresh) }
  }

  private var favoriteButton: some View {
    Button {
      store.send(.favoriteTapped)
    } label: {
      if store.movie.favorite {
        Image(systemName: "star.fill")
          .foregroundStyle(Utils.favoriteColor)
          .transition(.confetti(color: Utils.favoriteColor, size: 3, enabled: store.animateButton))
      } else {
        Image(systemName: "star")
      }
    }
  }
}

private struct ActorsListView: View {
  var actors: [Actor]
  let send: ((MovieActorsFeature.Action) -> StoreTask)?

  var body: some View {
    List(actors, id: \.modelId) { actor in
      if let send {
        Button {
          _ = send(.detailButtonTapped(actor))
        } label: {
          Utils.ActorView(actor: actor, showChevron: true)
        }
      } else {
        NavigationLink(state: RootFeature.showActorMovies(actor)) {
          Utils.ActorView(actor: actor, showChevron: false)
        }
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
