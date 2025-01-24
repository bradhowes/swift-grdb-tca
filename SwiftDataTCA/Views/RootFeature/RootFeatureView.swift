import ComposableArchitecture
import SwiftUI

@MainActor
struct RootFeatureView: View {
  @Bindable var store: StoreOf<RootFeature> = Store(initialState: .init()) { RootFeature() }

#if os(iOS)
  init() {
    UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
      .lineBreakMode = .byTruncatingMiddle
  }
#endif

  var body: some View {
    FromStateView(store: store.scope(state: \.fromState, action: \.fromState))
      .padding()
  }
}

extension RootFeatureView {
  static var preview: some View {
    RootFeatureView()
  }
}

#Preview {
  RootFeatureView.preview
}
