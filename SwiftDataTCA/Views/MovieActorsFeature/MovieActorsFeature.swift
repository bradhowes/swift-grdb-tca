import ComposableArchitecture
import Dependencies
import Foundation
import IdentifiedCollections
import Models
import SharedGRDB
import SwiftData
import SwiftUI

@Reducer
struct MovieActorsFeature {

  @ObservableState
  struct State: Equatable {
    var movie: Movie
    @Shared(.appStorage("nameSort")) var nameSort: Ordering = .forward
    @SharedReader var actors: IdentifiedArrayOf<Actor>
    var animateButton = false

    init(movie: Movie, nameSort: Ordering = .forward) {
      self.movie = movie
      _actors = .init(
        .fetch(
          MovieActorsQuery(movie: movie, ordering: _nameSort.wrappedValue.sortOrder),
          animation: .smooth
        )
      )
    }
  }

  enum Action: Sendable {
    case detailButtonTapped(Actor)
    case favoriteTapped
    case nameSortChanged(Ordering)
    case refresh
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .detailButtonTapped: return .none
      case .favoriteTapped: return toggleFavoriteState(state: &state)
      case .nameSortChanged(let newSort): return setNameSort(newSort, state: &state)
      case .refresh: return updateQuery(state)
      }
    }
  }
}

extension MovieActorsFeature {

  private func updateQuery(_ state: State) -> Effect<Action> {
    let nameSort = state.nameSort
    return .run { _ in
      do {
        try await state.$actors.load(
          .fetch(
            MovieActorsQuery(movie: state.movie, ordering: nameSort.sortOrder),
            animation: .smooth
          )
        )
      } catch {
        reportIssue(error)
      }
    }
    .cancellable(id: "MovieActorsFeature.updateQuery")
  }

  private func setNameSort(_ newSort: Ordering, state: inout State) -> Effect<Action> {
    state.$nameSort.withLock { $0 = newSort }
    return updateQuery(state)
  }

  func toggleFavoriteState(state: inout State) -> Effect<Action> {
    @Dependency(\.defaultDatabase) var database
    try? database.write { try state.movie.toggleFavorite(in: $0) }
    state.animateButton = state.movie.favorite
    return .none
  }
}

#Preview {
  MovieActorsView.preview
}
