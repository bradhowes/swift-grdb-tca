import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI

@Reducer
struct FromQueryFeature {

  @Reducer
  enum Path {
    case showMovieActors(MovieActorsFeature)
    case showActorMovies(ActorMoviesFeature)
  }

  @ObservableState
  struct State {
    var path = StackState<Path.State>()
    var titleSort: SortOrder? = .forward
    var isSearchFieldPresented = false
    var searchString: String = ""
    var fetchDescriptor: FetchDescriptor<Movie> { .init(predicate: self.predicate, sortBy: self.sort) }
    var predicate: Predicate<Movie> {
      #Predicate<Movie> {
        searchString.isEmpty ? true : $0.title.localizedStandardContains(searchString)
      }
    }
    var sort: [SortDescriptor<Movie>] { [sortBy(\.sortableTitle, order: titleSort)].compactMap { $0 } }

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
    case movieSelected(Movie)
    case path(StackActionOf<Path>)
    case searchStringChanged(String)
    case titleSortChanged(SortOrder?)
  }

  @Dependency(\.database) var db

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        db.add()
        db.save()
        return .none

      case .deleteSwiped(let movie):
        db.delete(movie)
        db.save()
        return .none

      case .favoriteSwiped(let movie):
        movie.favorite.toggle()
        return .none

      case .movieSelected(let movie):
        state.path.append(.showMovieActors(MovieActorsFeature.State(movie: movie)))
        return .none

      case .path(let pathAction):
        // Watch for and handle the selections of child views. By doing so, we do not have to share
        // the `StackState` with the child features.
        switch pathAction {
        case .element(id: _, action: .showMovieActors(.actorSelected(let actor))):
          state.path.append(.showActorMovies(ActorMoviesFeature.State(actor: actor)))

        case .element(id: _, action: .showActorMovies(.movieSelected(let movie))):
          state.path.append(.showMovieActors(MovieActorsFeature.State(movie: movie)))

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
        return .none

      case .titleSortChanged(let newSort):
        state.titleSort = newSort
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}

#Preview {
  FromQueryView.preview
}
