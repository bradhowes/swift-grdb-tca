import Combine
import ComposableArchitecture
import Foundation
import Models
import Sharing
import SQLiteData
import SwiftUI

@Reducer
struct RootFeature {

  @Reducer
  enum Path {
    case showMovieActors(MovieActorsFeature)
    case showActorMovies(ActorMoviesFeature)
  }

  @ObservableState
  struct State: Equatable {
    var path = StackState<Path.State>()
    @ObservationStateIgnored
    @Fetch var movies: MovieCollection
    var isSearchFieldPresented = false
    var scrollTo: Movie?
    var highlight: Movie?
    var titleSort: Ordering
    var searchText: String = ""

    init() {
      let sort = Ordering.forward
      self.titleSort = sort
      self._movies = .init(wrappedValue: .init(), AllMoviesQuery(ordering: sort.sortOrder))
    }
  }

  enum Action {
    case addButtonTapped
    case clearHighlight
    case deleteSwiped(Movie)
    case favoriteSwiped(Movie)
    case highlight(Movie)
    case movieButtonTapped(Movie)
    case path(StackActionOf<Path>)
    case queryUpdated
    case searchButtonTapped(Bool)
    case searchTextChanged(String)
    case scrollToMovie(Movie)
    case titleSortChanged(Ordering)
    case toggleFavoriteState(Movie)
  }

  @Dependency(\.defaultDatabase) var database

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {

      case .addButtonTapped:
        let next = Support.nextMockMovieEntry(state.movies)
        guard let movie = try? database.write({ try Movie.make(db: $0, entry: next) }) else {
          return .none
        }
        return .run { send in
          await send(.scrollToMovie(movie))
          await send(.highlight(movie))
        }

      case .clearHighlight:
        state.highlight = nil
        return .none

      case .deleteSwiped(let movie):
        _ = try? database.write { db in
          try? Movie.delete(movie)
            .execute(db)
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

      case .queryUpdated:
        return .none

      case .searchButtonTapped(let enabled):
        state.isSearchFieldPresented = enabled
        if !enabled {
          state.searchText = ""
          return updateQuery(state)
        }
        return .none

      case .scrollToMovie(let movie):
        state.scrollTo = movie
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

      case .toggleFavoriteState(var movie):
        return Utils.toggleFavoriteState(&movie)
      }
    }
    .forEach(\.path, action: \.path)
  }
}

extension RootFeature.Path.State: Equatable {}

extension RootFeature {

  private func monitorPathChange(_ pathAction: StackActionOf<Path>, state: inout State) -> Effect<Action> {
    print("pathAction:", pathAction)
    switch pathAction {
    case .element(id: _, action: .showMovieActors(.detailButtonTapped(let actor))):
      state.path.append(.showActorMovies(.init(actor: actor)))

    case .element(id: _, action: .showActorMovies(.detailButtonTapped(let movie))):
      state.path.append(.showMovieActors(.init(movie: movie)))

    default: break
    }
    return .none
  }

  private func updateQuery(_ state: State) -> Effect<Action> {
    let searchText = state.searchText.isEmpty ? nil : state.searchText
    let titleSort = state.titleSort
    let movies = state.$movies
    return .run { send in
      do {
        try await movies.load(
          AllMoviesQuery(ordering: titleSort.sortOrder, searchText: searchText),
          animation: .smooth
        )
        await send(.queryUpdated)
      } catch {
        reportIssue(error)
      }
    }
    .cancellable(id: "RootFeature.updateQuery", cancelInFlight: true)
  }
}

#Preview {
  RootView.previewWithButtons
}
