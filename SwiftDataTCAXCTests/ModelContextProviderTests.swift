import Foundation
import SwiftData
import XCTest

@testable import SwiftDataTCA

final class ModelContextProviderTests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }

  func testMakeLiveContainer() async throws {
    let tmp = URL.temporaryDirectory.appending(component: "Model.db", directoryHint: .notDirectory)
    try? FileManager.default.removeItem(at: tmp)
    let container = makeLiveContainer(dbFile: tmp)
    let context = ModelContext(container)
    try? Support.generateMocks(context: context, count: 20)
    let movies = try context.fetch(ActiveSchema.movieFetchDescriptor(titleSort: .none, search: ""))
    XCTAssertEqual(20, movies.count)
  }
}
