import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI

@Reducer
struct FromStateFeature {
  @ObservableState
  struct State {
    var movies: [Movie] = []
    var titleSort: SortOrder? = .forward
    var uuidSort: SortOrder?
    var isSearchFieldPresented = false
    var searchString: String = ""
    var fetchDescriptor: FetchDescriptor<Movie> { .init(predicate: self.predicate, sortBy: self.sort) }
    var predicate: Predicate<Movie> {
      #Predicate<Movie> {
        searchString.isEmpty ? true : $0.title.localizedStandardContains(searchString)
      }
    }
    var sort: [SortDescriptor<Movie>] {
      [sortBy(\.sortableTitle, order: titleSort), sortBy(\.id, order: uuidSort)].compactMap { $0 }
    }

    private func sortBy<Value: Comparable>(_ key: KeyPath<Movie, Value>, order: SortOrder?) -> SortDescriptor<Movie>? {
      guard let order else { return nil }
      return .init(key, order: order)
    }
  }

  enum Action: Sendable {
    case actorButtonTapped(Actor)
    case addButtonTapped
    case deleteSwiped(Movie)
    case favoriteSwiped(Movie)
    case onAppear
    case searchButtonTapped(Bool)
    case searchStringChanged(String)
    case titleSortChanged(SortOrder?)
    case uuidSortChanged(SortOrder?)
    // Reducer-only action to refresh the array of movies when another action changed what would be returned by the
    // `fetchDescriptor`.
    case _fetchMovies
  }

  @Dependency(\.movieDatabase) var db

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .actorButtonTapped(let actor):
        print(actor.name)
        return .none

      case .addButtonTapped:
        db.add()
        db.save()
        return runSendFetchMovies

      case .deleteSwiped(let movie):
        db.delete(movie)
        db.save()
        return runSendFetchMovies

      case .favoriteSwiped(let movie):
        movie.favorite.toggle()
        return .none

      case .onAppear:
        fetchChanges(state: &state)
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

      case .uuidSortChanged(let newSort):
        state.uuidSort = newSort
        return runSendFetchMovies

      case ._fetchMovies:
        fetchChanges(state: &state)
        return .none
      }
    }
  }

  private var runSendFetchMovies: Effect<Action> {
    .run { @MainActor send in
      send(._fetchMovies, animation: .default)
    }
  }

  private func fetchChanges(state: inout State) {
    @Dependency(\.movieDatabase) var db
    state.movies = db.fetchMovies(state.fetchDescriptor)
  }
}

#Preview {
  FromStateView.preview
}
