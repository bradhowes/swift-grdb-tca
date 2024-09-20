#if canImport(Testing)

import ComposableArchitecture
import Dependencies
import Foundation
import SwiftData
import Testing

@testable import SwiftDataTCA

struct DatabaseTests {

  @Test("Creating DB")
  func creatingDatabase() async throws {
    typealias ActiveSchema = SchemaV6
    let schema = Schema(versionedSchema: ActiveSchema.self)
    let config = ModelConfiguration("V55555", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = ModelContext(container)

    @Sendable
    func doFetchMovies(_ descriptor: FetchDescriptor<MovieModel>) -> [MovieModel] {
      @Dependency(\.modelContextProvider) var context
      return (try? context.fetch(descriptor)) ?? []
    }

    @Sendable
    func doAdd() -> MovieModel {
      @Dependency(\.modelContextProvider) var context
      return ActiveSchema.makeMock(context: context, entry: Support.nextMockMovieEntry(context: context))
    }

    @Sendable
    func doDelete(_ model: MovieModel) {
      @Dependency(\.modelContextProvider) var context
      context.delete(model)
      try? context.save()
    }

    @Sendable
    func doSave() {
      @Dependency(\.modelContextProvider) var context
      try? context.save()
    }

    withDependencies {
      $0.modelContextProvider = context
      $0.uuid = .incrementing
      $0.database = Database(
        fetchMovies: doFetchMovies,
        add: doAdd,
        delete: doDelete,
        save: doSave
      )
    } operation: {
      @Dependency(\.database) var db
      var movies = db.fetchMovies(FetchDescriptor<MovieModel>())
      #expect(movies.count == 0)

      _ = db.add()
      _ = db.add()
      _ = db.add()
      db.save()

      movies = db.fetchMovies(FetchDescriptor<MovieModel>())
      #expect(movies.count == 3)
    }
  }

  @Test("Exercising Live DB Value")
  func exercisingLiveDatabase() async throws {
    typealias ActiveSchema = SchemaV6
    let schema = Schema(versionedSchema: ActiveSchema.self)
    let config = ModelConfiguration("V55555", schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = ModelContext(container)

    withDependencies {
      $0.modelContextProvider = context
      $0.uuid = .incrementing
    } operation: {
      @Dependency(\.database) var db
      var movies = db.fetchMovies(FetchDescriptor<MovieModel>())
      #expect(movies.count == 0)

      let movie = db.add()
      _ = db.add()
      _ = db.add()
      db.save()

      movies = db.fetchMovies(FetchDescriptor<MovieModel>())
      #expect(movies.count == 3)

      db.delete(movie)
      movies = db.fetchMovies(FetchDescriptor<MovieModel>())
      #expect(movies.count == 2)
    }
  }
}

#endif
