import ComposableArchitecture
import Foundation
import IdentifiedCollections
import SwiftData
import SwiftUI

@Reducer
struct MovieActorsFeature {

  @ObservableState
  struct State: Equatable {
    var movie: Movie
    var nameSort: SortOrder?
    @SharedReader var actors: [Actor]
    var animateButton = false

    init(movie: Movie, nameSort: SortOrder? = .forward) {
      self.movie = movie
      self.nameSort = nameSort
      _actors = Self.makeQuery(movie: movie, nameSort: nameSort)
    }

    static func makeQuery(movie: Movie, nameSort: SortOrder?) -> SharedReader<[Actor]> {
      SharedReader(.fetchAll(query: movie.actors.order(nameSort?.by(Actor.Columns.name))))
    }

    mutating func updateQuery() {
      _actors = Self.makeQuery(movie: movie, nameSort: nameSort)
    }
  }

  enum Action: Sendable {
    case detailButtonTapped(Actor)
    case favoriteTapped
    case nameSortChanged(SortOrder?)
    case refresh
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .detailButtonTapped: return .none
      case .favoriteTapped: return toggleFavoriteState(state: &state)
      case .nameSortChanged(let newSort): return setNameSort(newSort, state: &state)
      case .refresh: return refresh(state: &state)
      }
    }
  }
}

extension MovieActorsFeature {

  private func refresh(state: inout State) -> Effect<Action> {
    state.updateQuery()
    return .none
  }

  private func setNameSort(_ newSort: SortOrder?, state: inout State) -> Effect<Action> {
    state.nameSort = newSort
    state.updateQuery()
    return .none
  }

  func toggleFavoriteState(state: inout State) -> Effect<Action> {
    state.movie.toggleFavorite()
    state.animateButton = state.movie.favorite
    return .none
  }
}

#Preview {
  MovieActorsView.preview
}
