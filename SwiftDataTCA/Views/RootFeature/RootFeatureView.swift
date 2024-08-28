import ComposableArchitecture
import SwiftUI

// swiftlint:disable indentation_width
@MainActor
struct RootFeatureView: View {
  @Bindable var store: StoreOf<RootFeature> = Store(initialState: .init()) { RootFeature() }

  init() {
#if os(iOS)
    UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
      .lineBreakMode = .byTruncatingMiddle
#endif
  }

  var body: some View {
    TabView(selection: $store.activeTab.sending(\.tabChanged)) {
      FromStateView(store: .init(initialState: .init()) {
        FromStateFeature()
        // ._printChanges()
      })
      .padding()
      .tabItem {
        Label("FromState", systemImage: "1.circle")
      }
      .tag(RootFeature.Tab.fromStateFeature)

      FromQueryView(store: .init(initialState: .init()) {
        FromQueryFeature()
        // ._printChanges()
      })
      .padding()
      .tabItem {
        Label("FromQuery", systemImage: "2.circle")
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
