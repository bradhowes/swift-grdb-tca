import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI

@Reducer
struct FromQueryFeature {
  @ObservableState
  struct State {
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
    case addButtonTapped
    case searchButtonTapped(Bool)
    case deleteSwiped(Movie)
    case favoriteSwiped(Movie)
    case searchStringChanged(String)
    case titleSortChanged(SortOrder?)
    case uuidSortChanged(SortOrder?)
    // Reducer-only action used to refresh the Xcode preview after adding a new movie.
    case _refreshQuery
  }

  @Dependency(\.movieDatabase) var db

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        db.add(Movie.mock)
        db.save()
        if SwiftDataTCA.previewing {
          // For some reason adding a new item does not trigger a refresh in a preview. We need to tweak the query to
          // force SwiftUI to refetch the Query.
          return runSendRefreshQuery
        }
        return .none

      case .searchButtonTapped(let searching):
        state.isSearchFieldPresented = searching
        return .none

      case .deleteSwiped(let movie):
        // NOTE: preview appears to work OK, but a `Query` refresh will show it. Works
        // fine in simulator and on device.
        db.delete(movie)
        db.save()
        return .none

      case .favoriteSwiped(let movie):
        movie.favorite.toggle()
        return .none

      case .searchStringChanged(let newString):
        guard newString != state.searchString else { return .none }
        state.searchString = newString
        return .none

      case .titleSortChanged(let newSort):
        state.titleSort = newSort
        return .none

      case .uuidSortChanged(let newSort):
        state.uuidSort = newSort
        return .none

      case ._refreshQuery:
        state.searchString = "blah"
        state.searchString = ""
        return .none
      }
    }
  }

  private var runSendRefreshQuery: Effect<Action> {
    .run { @MainActor send in
      send(._refreshQuery, animation: .default)
    }
  }
}

#Preview {
  FromQueryView.preview
}
