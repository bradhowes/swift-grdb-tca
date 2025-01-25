import ComposableArchitecture
import Dependencies
import Foundation
import IdentifiedCollections
import Models
import SharedGRDB
import SwiftUI

@Reducer
struct MovieActorsFeature {

  @ObservableState
  struct State: Equatable {
    var movie: Movie
    @Shared(.appStorage("MovieActorsFeature-nameSort")) var nameSort: Ordering = .forward
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
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .detailButtonTapped: return .none
      case .favoriteTapped: return toggleFavoriteState(state: &state)
      case .nameSortChanged(let newSort): return setNameSort(newSort, state: &state)
      }
    }
  }
}

extension MovieActorsFeature {

  private func updateQuery(_ state: State) -> Effect<Action> {
    let movie = state.movie
    let sortOrder = state.nameSort.sortOrder
    return .run { _ in
      do {
        print("MovieActorssFeature.updateQuery BEGIN")
        try await state.$actors.load(
          .fetch(
            MovieActorsQuery(movie: movie, ordering: sortOrder),
            animation: .smooth
          )
        )
        print("MovieActorssFeature.updateQuery END")
      } catch {
        reportIssue(error)
      }
    }
    .cancellable(id: "MovieActorsFeature.updateQuery", cancelInFlight: true)
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
