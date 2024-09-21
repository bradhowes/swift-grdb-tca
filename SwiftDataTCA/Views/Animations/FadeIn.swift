import SwiftUI

struct FadeInModifier: ViewModifier {
  let enabled: Bool
  let duration: Double
  let completion: () -> Void

  @State private var opacity = 0.2

  func body(content: Content) -> some View {
    if enabled {
      content
        .opacity(opacity)
        .onAppear {
          withAnimation(.easeIn(duration: duration)) {
            opacity = 1.0
          } completion: {
            completion()
          }
        }
    } else {
      content
    }
  }
}

extension View {
  func fadeIn(
    enabled: Bool,
    duration: Double = 0.1,
    completion: @escaping () -> Void = {}
  ) -> some View {
    modifier(FadeInModifier(enabled: enabled, duration: duration, completion: completion))
  }
}

struct FadeInDemoView: View {
  @State private var isFavorite: Bool

  init(isFavorite: Bool = false) {
    self.isFavorite = isFavorite
  }

  var body: some View {
    VStack(spacing: 60) {
      ForEach([Font.body, Font.largeTitle, Font.system(size: 72)], id: \.self) { font in
        Button {
          isFavorite.toggle()
        } label: {
          if isFavorite {
            Image(systemName: "star.fill")
              .foregroundStyle(Utils.favoriteColor)
              .fadeIn(enabled: true, duration: 1.5)
          } else {
            Image(systemName: "star")
              .foregroundStyle(.gray)
          }
        }
        .font(font)
      }
    }
  }
}

#Preview {
  FadeInDemoView()
}
