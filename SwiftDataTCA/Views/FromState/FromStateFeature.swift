import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI

@Reducer
struct FromStateFeature {
  typealias Path = RootFeature.Path

  @ObservableState
  struct State: Equatable {
    var path = StackState<Path.State>()
    var movies: [Movie] = []
    var titleSort: SortOrder? = .forward
    var isSearchFieldPresented = false
    var searchString: String = ""
    var fetchDescriptor: FetchDescriptor<MovieModel> {
      ActiveSchema.movieFetchDescriptor(titleSort: self.titleSort, searchString: searchString)
    }
  }

  enum Action: Sendable {
    case addButtonTapped
    case deleteSwiped(Movie)
    case favoriteSwiped(Movie)
    case movieSelected(Movie)
    case onAppear
    case path(StackActionOf<Path>)
    case searchButtonTapped(Bool)
    case searchStringChanged(String)
    case titleSortChanged(SortOrder?)
    // Reducer-only action to refresh the array of movies when another action changed what would be returned by the
    // `fetchDescriptor`.
    case _fetchMovies
  }

  @Dependency(\.database) var db

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        _ = db.add()
        return runSendFetchMovies

      case .deleteSwiped(let movie):
        db.delete(movie.backingObject())
        db.save()
        return runSendFetchMovies

      case .favoriteSwiped(var changed):
        // Could be improved on
        let update = changed.toggleFavorite()
        for (index, movie) in state.movies.enumerated() where movie.modelId == changed.modelId {
          state.movies[index] = update
        }
        return .none

      case .movieSelected(let movie):
        state.path.append(.showMovieActors(MovieActorsFeature.State(movie: movie)))
        return .none

      case .onAppear:
        fetchChanges(state: &state)
        return .none

      case .path(let pathAction):
        print("FromStateFeature.path - \(String(describing: pathAction))")
        switch pathAction {
        case .popFrom:
          if state.path.count == 1 {
            fetchChanges(state: &state)
          }

        default:
          break
        }
        return .none

      case .searchButtonTapped(let searching):
        state.isSearchFieldPresented = searching
        return .none

      case .searchStringChanged(let newString):
        guard newString != state.searchString else { return .none }
        state.searchString = newString
        return runSendFetchMovies

      case .titleSortChanged(let newSort):
        state.titleSort = newSort
        return runSendFetchMovies

      case ._fetchMovies:
        fetchChanges(state: &state)
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }

  private var runSendFetchMovies: Effect<Action> {
    .run { @MainActor send in
      send(._fetchMovies, animation: .default)
    }
  }

  private func fetchChanges(state: inout State) {
    @Dependency(\.database) var db
    state.movies = db.fetchMovies(state.fetchDescriptor).map { $0.valueType }
  }
}

#Preview {
  FromStateView.preview
}
