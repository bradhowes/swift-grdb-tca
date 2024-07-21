import Dependencies
import SwiftData
import SwiftUI

struct RootContentView: View {
  @Dependency(\.modelContextProvider) var modelContextProvider

  enum Tab {
    case contentView, queryView
  }

  @State private var selectedTab: Tab = .contentView

  init() {
    // Configure navigation titles to truncate in the middle.
    UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
      .lineBreakMode = .byTruncatingMiddle
  }

  var body: some View {
    // swiftlint:disable indentation_width
    TabView(selection: $selectedTab) {
      FromStateView(store: .init(initialState: .init()) {
        FromStateFeature()
#if PRINT_CHANGES
          ._printChanges()
#endif
      })
      .padding()
      .tabItem {
        Label("State", systemImage: "1.circle")
      }
      .tag(Tab.contentView)
      FromQueryView(store: .init(initialState: .init()) {
        FromQueryFeature()
#if PRINT_CHANGES
          ._printChanges()
#endif
      })
      .padding()
      .tabItem {
        Label("Query", systemImage: "2.circle")
      }
      .tag(Tab.queryView)
    }
    .modelContext(modelContextProvider.context)
  }
  // swiftlint:enable indentation_width
}

extension RootContentView {
  static var preview: some View {
    @Dependency(\.modelContextProvider) var modelContextProvider
    Support.generateMocks(context: modelContextProvider.context, count: 40)
    return RootContentView()
  }
}

#Preview {
  RootContentView.preview
}
