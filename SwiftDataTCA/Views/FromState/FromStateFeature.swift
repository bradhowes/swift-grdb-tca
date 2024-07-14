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
    var predicate: Predicate<Movie> {
      #Predicate<Movie> {
        searchString.isEmpty ? true : $0.title.localizedStandardContains(searchString)
      }
    }

    var fetchDescriptor: FetchDescriptor<Movie> { .init(predicate: self.predicate, sortBy: self.sort) }

    var sort: [SortDescriptor<Movie>] {
      return [
        self.titleSort != nil ? .init(\.sortableTitle, order: self.titleSort!) : nil,
        self.uuidSort != nil ? .init(\.id, order: self.uuidSort!) : nil,
      ].compactMap { $0 }
    }
  }

  enum Action: Sendable {
    case addButtonTapped
    case deleteSwiped(Movie)
    case favoriteSwiped(Movie)
    case onAppear
    case searchButtonTapped(Bool)
    case searchStringChanged(String)
    case titleSortChanged(SortOrder?)
    case uuidSortChanged(SortOrder?)
    // Reducer-only action to refresh the array of movies when another action changed the number of movies
    case _fetchChanges
  }

  @Dependency(\.movieDatabase) var db

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {

      case .addButtonTapped:
        db.add(Movie.mock)
        return runSendFetchChanges

      case .deleteSwiped(let movie):
        db.delete(movie)
        return runSendFetchChanges

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
        return runSendFetchChanges

      case .titleSortChanged(let newSort):
        state.titleSort = newSort
        return runSendFetchChanges

      case .uuidSortChanged(let newSort):
        state.uuidSort = newSort
        return runSendFetchChanges

      case ._fetchChanges:
        fetchChanges(state: &state)
        return .none
      }
    }
  }

  private var runSendFetchChanges: Effect<Action> {
    .run { @MainActor send in
      send(._fetchChanges, animation: .default)
    }
  }

  private func fetchChanges(state: inout State) {
    @Dependency(\.movieDatabase) var db
    state.movies = (try? db.fetch(state.fetchDescriptor)) ?? []
  }
}


#Preview {
  FromStateView.preview
}
