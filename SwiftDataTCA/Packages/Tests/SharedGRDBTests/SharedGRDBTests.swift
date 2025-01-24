import Dependencies
import Foundation
import GRDB
import Testing

@Test func testDependencyKey() async throws {
  @Dependency(\.date) var date
  @Dependency(\.date.now) var now

  withDependencies {
    $0.date.now = Date(timeIntervalSinceReferenceDate: 0)
  } operation: {
    #expect( now == Date(timeIntervalSinceReferenceDate: 0))
    #expect( date() == Date(timeIntervalSinceReferenceDate: 0))
  }
}
