import Dependencies
import Foundation
import SwiftData

/// Schema v6 - rename models and operate with structs in views
enum SchemaV6: VersionedSchema {
  static var versionIdentifier: Schema.Version { .init(6, 0, 0) }

  static var models: [any PersistentModel.Type] {
    [
      ActorModel.self,
      MovieModel.self
    ]
  }

  @Model
  final class ActorModel {
    var name: String
    var movies: [MovieModel]

    init(name: String) {
      self.name = name
      self.movies = []
    }

    var valueType: Actor { .init(modelId: persistentModelID, name: name) }
  }

  @Model
  final class MovieModel {
    var title: String
    var favorite: Bool = false
    var sortableTitle: String = ""
    @Relationship(inverse: \ActorModel.movies) var actors: [ActorModel]

    init(title: String, favorite: Bool = false) {
      self.title = title
      self.favorite = favorite
      self.sortableTitle = Support.sortableTitle(title)
      self.actors = []
    }

    var valueType: Movie { .init(modelId: persistentModelID, name: title, favorite: favorite) }
  }

  struct Actor {
    let modelId: PersistentIdentifier
    let name: String

    func movies(ordering: SortOrder?) -> [Movie] {
      @Dependency(\.modelContextProvider) var context
      return Support.sortedMovies(for: backingObject(), order: ordering).map(\.valueType)
    }

    @discardableResult
    private func backingObject() -> ActorModel {
      @Dependency(\.modelContextProvider) var context
      guard let actor = context.model(for: self.modelId) as? ActorModel else {
        fatalError("Faied to resolve \(self.name) usiing \(self.modelId)")
      }
      return actor
    }
  }

  struct Movie {
    let modelId: PersistentIdentifier
    let name: String
    let favorite: Bool

    func toggleFavorite() -> Movie {
      backingObject { $0.favorite.toggle() }
      return .init(modelId: modelId, name: name, favorite: !favorite)
    }

    func actors(ordering: SortOrder?) -> [Actor] {
      Support.sortedActors(for: backingObject(), order: ordering).map(\.valueType)
    }

    @discardableResult
    func backingObject(performing: ((MovieModel) -> Void)? = nil) -> MovieModel {
      @Dependency(\.modelContextProvider) var context
      guard let movie = context.model(for: self.modelId) as? MovieModel else {
        fatalError("Faied to resolve \(self.name) usiing \(self.modelId)")
      }
      if let performing {
        performing(movie)
        try? context.save()
      }
      return movie
    }
  }
}

extension SchemaV6.Actor: Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool { lhs.modelId == rhs.modelId }
}

extension SchemaV6.Actor: Identifiable {
  public var id: PersistentIdentifier { modelId }
}

extension SchemaV6.Movie: Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool { lhs.modelId == rhs.modelId && lhs.favorite == rhs.favorite }
}

extension SchemaV6.Movie: Identifiable {
  public var id: PersistentIdentifier { modelId }
}

extension SchemaV6 {

  @discardableResult
  static func makeMock(context: ModelContext, entry: (title: String, cast: [String])) -> MovieModel {
    let movie = MovieModel(title: entry.0)
    context.insert(movie)

    let actors = entry.cast.map { fetchOrMakeActor(context, name: $0) }
    movie.actors = actors
    for actor in actors {
      actor.movies.append(movie)
    }

    try? context.save()

    return movie
  }

  static func fetchOrMakeActor(_ context: ModelContext, name: String) -> ActorModel {
    let predicate = #Predicate<ActorModel> { $0.name == name }
    let fetchDescriptor = FetchDescriptor<ActorModel>(predicate: predicate)
    if let actors = (try? context.fetch(fetchDescriptor)), !actors.isEmpty {
      return actors[0]
    }

    let actor = ActorModel(name: name)
    context.insert(actor)

    return actor
  }

  @inlinable
  static func searchPredicate(_ search: String) -> Predicate<MovieModel>? {
    search.isEmpty ? nil : #Predicate<MovieModel> { $0.title.localizedStandardContains(search) }
  }

  /**
   Obtain a `FetchDescriptor` that will return an ordered (optional) and possibly filtered set of known `_Movie`
   entities. Ordering is done on the `_Movie.title` attribute when `titleSort` is not nil. Otherwise, ordering
   is undetermined.

   - parameter titleSort: the direction of the ordering -- alphabetical or reveresed alphabetical
   - parameter searchString: if not empty, only return `_Movie` entities whose `title` contains the search string
   - returns: new `FetchDescriptor`
   */
  @inlinable
  static func movieFetchDescriptor() -> FetchDescriptor<MovieModel> {
    FetchDescriptor<MovieModel>()
  }

  /**
   Obtain a `FetchDescriptor` that will return an ordered (optional) and possibly filtered set of known `_Movie`
   entities. Ordering is done on the `_Movie.title` attribute when `titleSort` is not nil. Otherwise, ordering
   is undetermined.

   - parameter titleSort: the direction of the ordering -- alphabetical or reveresed alphabetical
   - parameter search: if not empty, only return `_Movie` entities whose `title` contains the search string
   - returns: new `FetchDescriptor`
   */
  static func movieFetchDescriptor(
    titleSort: SortOrder? = .forward,
    search: String = ""
  ) -> FetchDescriptor<MovieModel> {
    let sortBy: [ SortDescriptor<MovieModel>] = Support.sortBy(.sortBy(\.sortableTitle, order: titleSort))
    var fetchDescriptor = FetchDescriptor(predicate: searchPredicate(search), sortBy: sortBy)
    fetchDescriptor.relationshipKeyPathsForPrefetching = [\.actors]
    return fetchDescriptor
  }
}

extension SchemaV6.MovieModel: Sendable {}
extension SchemaV6.ActorModel: Sendable {}
