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
      case .addButtonTapped: addButtonTapped(&state)
      case .clearHighlight: clearHighlight(&state)
      case .deleteSwiped(let movie): deleteSwipedMovie(&state, movie: movie)
      case .movieButtonTapped(let movie): movieButtonTapped(&state, movie: movie)
      case .favoriteSwiped(let movie): favoriteSwiped(&state, movie: movie)
      case .highlight(let movie): highlightMovie(&state, movie: movie)
      case .path(let pathAction): monitorPathChange(pathAction, state: &state)
      case .queryUpdated: .none
      case .scrollToMovie(let movie): scrollToMovie(&state, movie: movie)
      case .searchButtonTapped(let enabled): searchButtonTapped(&state, enabled: enabled)
      case .searchTextChanged(let query): searchTextChanged(&state, query: query)
      case .titleSortChanged(let newSort): titleSortChanged(&state, newSort: newSort)
      case .toggleFavoriteState(var movie): Utils.toggleFavoriteState(&movie)
      }
    }
    .forEach(\.path, action: \.path)
  }
}

extension RootFeature.Path.State: Equatable {}

extension RootFeature {

  private func addButtonTapped(_ state: inout State) -> Effect<Action> {
    let next = Support.nextMockMovieEntry(state.movies)
    guard let movie = try? database.write({ try Movie.make(db: $0, entry: next) }) else {
      return .none
    }
    return .run { send in
      await send(.scrollToMovie(movie))
      await send(.highlight(movie))
    }
  }

  private func clearHighlight(_ state: inout State) -> Effect<Action> {
    state.highlight = nil
    return .none
  }

  private func deleteSwipedMovie(_ state: inout State, movie: Movie) -> Effect<Action> {
    _ = try? database.write { db in
      try? Movie.delete(movie)
        .execute(db)
    }
    return .none
  }

  private func favoriteSwiped(_ state: inout State, movie: Movie) -> Effect<Action> {
#if os(iOS)
    return Utils.beginFavoriteChange(.toggleFavoriteState(movie))
#endif
#if os(macOS)
    return Utils.toggleFavoriteState(movie)
#endif
  }

  private func highlightMovie(_ state: inout State, movie: Movie) -> Effect<Action> {
    state.highlight = movie
    return .none
  }

  private func monitorPathChange(_ pathAction: StackActionOf<Path>, state: inout State) -> Effect<Action> {
    print("pathAction:", pathAction)
    switch pathAction {
    case .element(id: _, action: .showActorMovies(.detailButtonTapped(let movie))):
      state.path.append(.showMovieActors(.init(movie: movie)))

    case .element(id: _, action: .showMovieActors(.detailButtonTapped(let actor))):
      state.path.append(.showActorMovies(.init(actor: actor)))

    default: break
    }
    return .none
  }

  private func movieButtonTapped(_ state: inout State, movie: Movie) -> Effect<Action> {
    state.path.append(.showMovieActors(.init(movie: movie)))
    return .none
  }

  private func scrollToMovie(_ state: inout State, movie: Movie) -> Effect<Action> {
    state.scrollTo = movie
    return .none
  }

  private func searchButtonTapped(_ state: inout State, enabled: Bool) -> Effect<Action> {
    state.isSearchFieldPresented = enabled
    if !enabled {
      state.searchText = ""
      return updateQuery(state)
    }
    return .none
  }

  private func searchTextChanged(_ state: inout State, query: String) -> Effect<Action> {
    if query != state.searchText {
      state.searchText = query
      return updateQuery(state)
    }
    return .none
  }

  private func titleSortChanged(_ state: inout State, newSort: Ordering) -> Effect<Action> {
    state.titleSort = newSort
    return updateQuery(state)
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
