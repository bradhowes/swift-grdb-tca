import SwiftUI
import SwiftData
import Dependencies

@main
struct SwiftDataTCAApp: App {
  @Dependency(\.modelContextProvider) var modelContextProvider

  enum Tab {
    case contentView, queryView
  }

  @State private var selectedTab: Tab = .contentView

  var body: some Scene {
    WindowGroup {
      TabView(selection: $selectedTab) {
        FromStateView(store: .init(initialState: .init()) { FromStateFeature()._printChanges() })
        .padding()
        .tabItem {
          Label("State", systemImage: "1.circle")
        }
        .tag(Tab.contentView)
        FromQueryView(store: .init(initialState: .init()) { FromQueryFeature()._printChanges() })
          .padding()
          .tabItem {
            Label("Query", systemImage: "2.circle")
          }
          .tag(Tab.queryView)
      }
      .modelContext(self.modelContextProvider.context())
    }
  }
}
