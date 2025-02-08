import Combine
import ComposableArchitecture
import Foundation
import Models
import Sharing
import SwiftUI

@Reducer
struct FromStateFeature {

  @Reducer(state: .equatable)
  enum Path {
    case showMovieActors(MovieActorsFeature)
    case showActorMovies(ActorMoviesFeature)
  }

  @ObservableState
  struct State: Equatable {
    var path = StackState<Path.State>()
    @SharedReader var movies: MovieCollection
    var isSearchFieldPresented = false
    var scrollTo: Movie?
    var highlight: Movie?
    var titleSort: Ordering
    var searchText: String = ""

    init() {
      let sort = Ordering.forward
      self.titleSort = sort
      _movies = SharedReader(
        .fetch(
          AllMoviesQuery(ordering: sort.sortOrder),
          animation: .smooth
        )
      )
    }
  }

  enum Action {
    case addButtonTapped
    case clearHighlight
    case clearScrollTo
    case deleteSwiped(Movie)
    case favoriteSwiped(Movie)
    case highlight(Movie)
    case movieButtonTapped(Movie)
    case path(StackActionOf<Path>)
    case searchButtonTapped(Bool)
    case searchTextChanged(String)
    case titleSortChanged(Ordering)
    case toggleFavoriteState(Movie)
  }

  @Dependency(\.defaultDatabase) var database

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {

      case .addButtonTapped:
        let next = Support.nextMockMovieEntry(state.movies)
        let movie = try? database.write { try Movie.makeMock(in: $0, entry: next, favorited: false) }
        state.scrollTo = movie
        return .none.animation()

      case .clearHighlight:
        state.highlight = nil
        return .none

      case .clearScrollTo:
        guard let movie = state.scrollTo else {
          return .none
        }

        state.scrollTo = nil
        return .run { @MainActor send in
          send(.highlight(movie), animation: .default)
        }

      case .deleteSwiped(let movie):
        _ = try? database.write { db in
          try? movie.delete(db)
        }
        return .none

      case .movieButtonTapped(let movie):
        state.path.append(.showMovieActors(.init(movie: movie)))
        return .none

      case .favoriteSwiped(let movie):
#if os(iOS)
        return Utils.beginFavoriteChange(.toggleFavoriteState(movie))
#endif
#if os(macOS)
        return Utils.toggleFavoriteState(movie)
#endif

      case .highlight(let movie):
        state.highlight = movie
        return .none

      case .path(let pathAction):
        return monitorPathChange(pathAction, state: &state)

      case .searchButtonTapped(let enabled):
        state.isSearchFieldPresented = enabled
        if !enabled {
          state.searchText = ""
          return updateQuery(state)
        }
        return .none

      case .searchTextChanged(let query):
        if query != state.searchText {
          state.searchText = query
          return updateQuery(state)
        }
        return .none

      case .titleSortChanged(let newSort):
        state.titleSort = newSort
        return updateQuery(state)

      case .toggleFavoriteState(let movie):
        _ = Utils.toggleFavoriteState(movie)
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}

extension FromStateFeature {

  private func updateQuery(_ state: State) -> Effect<Action> {
    let searchText = state.searchText.isEmpty ? nil : state.searchText
    let titleSort = state.titleSort
    let movies = state.$movies
    return .run { _ in
      do {
        print("-- FromStateFeature.updateQuery >>>")
        try await movies.load(
          .fetch(
            AllMoviesQuery(ordering: titleSort.sortOrder, searchText: searchText),
            animation: .smooth
          )
        )
        print("-- FromStateFeature.updateQuery <<<")
      } catch {
        reportIssue(error)
      }
    }
    .cancellable(id: "FromStateFeature.updateQuery", cancelInFlight: true)
  }

  private func monitorPathChange(_ pathAction: StackActionOf<Path>, state: inout State) -> Effect<Action> {
    switch pathAction {

    case .element(id: _, action: .showMovieActors(.detailButtonTapped(let actor))):
      state.path.append(.showActorMovies(.init(actor: actor)))

    case .element(id: _, action: .showActorMovies(.detailButtonTapped(let movie))):
      state.path.append(.showMovieActors(.init(movie: movie)))

    case .popFrom(let id):
      break

    default:
      break
    }
    return .none
  }
}

extension FromStateFeature {
//
//  @MainActor
//  static func link(_ movie: Movie) -> some View {
//    @Dependency(\.defaultDatabase) var database
//    return NavigationLink(state: Path.State.showMovieActors(.init(movie: movie))) {
//      // Fetch the actor names while we know that the Movie is valid.
//      Utils.MovieView(
//        name: movie.title,
//        favorite: movie.favorite,
//        actorNames: database.actors(for: movie).csv,
//        showChevron: false
//      )
//    }
//  }
}

#Preview {
  FromStateView.previewWithButtons
}
