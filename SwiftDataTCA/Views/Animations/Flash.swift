import SwiftUI

struct FlashModifier: ViewModifier {
  let enabled: Bool
  let count: Int
  let duration: Double
  let completion: () -> Void

  @State private var opacity = 1.0

  func body(content: Content) -> some View {
    if enabled {
      content
        .opacity(opacity)
        .onAppear {
          toggleOpacity(count: count)
        }
    } else {
      content
    }
  }

  func toggleOpacity(count: Int) {
    withAnimation(.linear(duration: duration)) {
      opacity = 0.0
    } completion: {
      withAnimation(.linear(duration: duration)) {
        opacity = 1.0
      } completion: {
        if count > 1 {
          toggleOpacity(count: count - 1)
        }
      }
    }
  }
}

extension View {
  func flash(
    enabled: Bool,
    count: Int = 2,
    duration: Double = 0.1,
    completion: @escaping () -> Void = {}
  ) -> some View {
    modifier(FlashModifier(enabled: enabled, count: count, duration: duration, completion: completion))
  }
}

struct FlashDemoView: View {
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
              .flash(enabled: true, duration: 0.1) {
                print("done")
              }
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
  FlashDemoView()
}
