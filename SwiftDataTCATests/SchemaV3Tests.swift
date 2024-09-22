#if canImport(Testing)

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import SwiftDataTCA

struct SchemaV3Tests {
  typealias ActiveSchema = SchemaV3

  /// NOTE to self: do not use `await container.mainContext` in tests
  /// NOTE to self: do not run Swift Data tests in parallel

  @Test func sortableTitle() async throws {
    #expect("world according to garp" == Support.sortableTitle("The World According to Garp"))
    #expect("mariachi" == Support.sortableTitle("El Mariachi"))
    #expect("way we were" == Support.sortableTitle("The Way We Were"))
    #expect("monde" == Support.sortableTitle("LE MONDE"))
    #expect("escuela" == Support.sortableTitle("LAs Escuela"))
    #expect("time to die" == Support.sortableTitle("a Time To Die"))
    #expect("hermanos" == Support.sortableTitle("lOs Hermanos"))
    #expect("piscine" == Support.sortableTitle("LA piscine"))
  }

  @Test func migrationV2V3() async throws {
    typealias OldSchema = SchemaV2

    let url = FileManager.default.temporaryDirectory.appending(component: "Model3.sqlite")
    try? FileManager.default.removeItem(at: url)
    let oldContext = TestingSupport.makeContext(OldSchema.self, storage: url)
    defer { TestingSupport.cleanup(oldContext) }

    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      @Dependency(\.uuid) var uuid

      oldContext.insert(OldSchema._Movie(id: uuid(), title: "El Mariachi", cast: ["Roberto"]))
      oldContext.insert(OldSchema._Movie(id: uuid(), title: "The Way We Were", cast: ["Babs", "Roberto"]))
      oldContext.insert(OldSchema._Movie(id: uuid(), title: "Le Monde", cast: ["Côme"]))
      oldContext.insert(OldSchema._Movie(id: uuid(), title: "Las Escuela", cast: ["Maria"]))
      oldContext.insert(OldSchema._Movie(id: uuid(), title: "La Piscine", cast: ["Valerie"]))
      oldContext.insert(OldSchema._Movie(id: uuid(), title: "A Time To Die", cast: ["Ralph", "Mary"]))
      oldContext.insert(OldSchema._Movie(id: uuid(), title: "Los Hermanos", cast: ["Harrison"]))
      oldContext.insert(OldSchema._Movie(id: uuid(), title: "Les Enfants", cast: ["Zoe"]))

      try! oldContext.save()
      let moviesV2 = try! oldContext.fetch(FetchDescriptor<OldSchema._Movie>(sortBy: [.init(\.title, order: .forward)]))
      #expect(moviesV2[0].title == "A Time To Die")
      #expect(moviesV2[1].title == "El Mariachi")
    }

    // Migrate to V3
    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      let newContext = TestingSupport.makeContext(ActiveSchema.self, migrationPlan: MockMigrationPlan.self, storage: url)
      defer { TestingSupport.cleanup(newContext) }

      let moviesV3 = try! newContext.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, uuidSort: nil, search: ""))
      #expect(moviesV3[0].sortableTitle == "enfants")
      #expect(moviesV3[0].title == "Les Enfants")
      #expect(moviesV3[1].sortableTitle == "escuela")
      #expect(moviesV3[1].title == "Las Escuela")
      #expect(moviesV3.last!.title == "The Way We Were")
    }
  }

  @Test func creatingV3Database() async throws {
    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      @Dependency(\.uuid) var uuid
      let context = TestingSupport.makeContext(ActiveSchema.self)
      defer { TestingSupport.cleanup(context) }
      let m1 = ActiveSchema._Movie(id: uuid(), title: "The First Movie", cast: ["Actor 1", "Actor 2", "Actor 3"])
      context.insert(m1)
      let m2 = ActiveSchema._Movie(id: uuid(), title: "A Second Movie", cast: ["Actor 1", "Actor 4"])
      context.insert(m2)
      let m3 = ActiveSchema._Movie(id: uuid(), title: "El Third Movie", cast: ["Actor 2"])
      context.insert(m3)
      try! context.save()
    }
  }

  @Test func fetchingV3() async throws {
    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      let context = TestingSupport.makeContext(ActiveSchema.self)
      defer { TestingSupport.cleanup(context) }

      ActiveSchema.makeMock(context: context, entry: ("A Second Movie", ["Actor 1", "Actor 4"]))
      ActiveSchema.makeMock(context: context, entry: ("The First Movie", ["Actor 1", "Actor 2", "Actor 3"]))
      ActiveSchema.makeMock(context: context, entry: ("El Third Movie", ["Actor 2"]))
      try! context.save()

      var movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .forward, uuidSort: .reverse, search: ""))

      #expect(movies.count == 3)
      #expect(movies[0].title == "The First Movie")
      #expect(movies[1].title == "A Second Movie")
      #expect(movies[2].title == "El Third Movie")

      #expect(movies[0].cast.count == 3)
      #expect(movies[0].cast[0] == "Actor 1")

      movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .reverse, uuidSort: .reverse, search: ""))
      #expect(movies.count == 3)
      #expect(movies[2].title == "The First Movie")
      #expect(movies[1].title == "A Second Movie")
      #expect(movies[0].title == "El Third Movie")

      movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, uuidSort: .forward, search: ""))
      #expect(movies.count == 3)
      #expect(movies[0].title == "A Second Movie")
      #expect(movies[1].title == "The First Movie")
      #expect(movies[2].title == "El Third Movie")

      movies = try! context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, uuidSort: .reverse, search: ""))
      #expect(movies.count == 3)
      #expect(movies[2].title == "A Second Movie")
      #expect(movies[1].title == "The First Movie")
      #expect(movies[0].title == "El Third Movie")
    }
  }
}

private enum MockMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] { [ SchemaV3.self, ] }
  static var stages: [MigrationStage] { [ StageV3.stage ] }
}

#endif
