import ComposableArchitecture
import SwiftUI

// swiftlint:disable indentation_width
struct RootFeatureView: View {

  @MainActor
  init() {
#if os(iOS)
    UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
      .lineBreakMode = .byTruncatingMiddle
#elseif os(macOS)
#endif
  }

  var body: some View {
    TabView {
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
      .tag(RootFeature.Tab.fromStateFeature)

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
      .tag(RootFeature.Tab.fromQueryFeature)
    }
  }
}
// swiftlint:enable indentation_width

extension RootFeatureView {
  static var preview: some View {
    @Dependency(\.modelContextProvider) var context
    return RootFeatureView()
      .modelContext(context)
  }
}

#Preview {
  RootFeatureView.preview
}
