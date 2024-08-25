import SwiftUI

struct ConfettiModifier<Style: ShapeStyle>: ViewModifier {
  private let duration = 0.3
  @State private var circleSize = 0.00001
  @State private var strokeMultiplier = 0.8
  @State private var confettiIsHidden = true
  @State private var confettiMovement = 0.7
  @State private var confettiScale = 1.0
  @State private var contentsScale = 0.00001

  var color: Style
  var size: Double

  func body(content: Content) -> some View {
    content
      .scaleEffect(contentsScale)
      .padding(10)
      .overlay(
        ZStack {
          GeometryReader { proxy in
            Circle()
              .strokeBorder(color, lineWidth: proxy.size.width / 2 * strokeMultiplier)
              .scaleEffect(circleSize * 1.0)
              .opacity(circleSize < 0.5 ? circleSize * 1.5 : 1.5 - circleSize)
            // Confetti bits
            ForEach(0..<30) { index in
              Circle()
                .fill(color)
                .frame(width: size + sin(Double(index)), height: size + sin(Double(index)))
                .scaleEffect(confettiScale)
                .offset(x: proxy.size.width / 2 * confettiMovement + (index.isMultiple(of: 2) ? size : 0))
                .rotationEffect(.degrees(12 * Double(index)))
                .offset(
                  x: (proxy.size.width - size) / 2,
                  y: (proxy.size.height - size) / 2
                )
                .opacity(confettiIsHidden ? 0 : 1)
            }
          }
        }
      )
      .padding(-10)
      .onAppear {
        withAnimation(.easeIn(duration: duration)) {
          circleSize = 1
        }
        withAnimation(.easeOut(duration: duration).delay(duration * 0.5)) {
          strokeMultiplier = 0.00001
        }
        withAnimation(.interpolatingSpring(stiffness: 50, damping: 5).delay(duration * 0.8)) {
          contentsScale = 1
        }
        withAnimation(.easeOut(duration: duration).delay(duration * 0.75)) {
          confettiIsHidden = false
          confettiMovement = 1.2
        }
        withAnimation(.easeOut(duration: duration).delay(duration * 1.4)) {
          confettiScale = 0.00001
        }
      }
  }
}

extension AnyTransition {
  static var confetti: AnyTransition {
    .modifier(
      active: ConfettiModifier(color: .blue, size: 3),
      identity: ConfettiModifier(color: .blue, size: 3)
    )
  }

  static func confetti<Style: ShapeStyle>(color: Style = .blue, size: Double = 3.0) -> AnyTransition {
    AnyTransition.modifier(
      active: ConfettiModifier(color: color, size: size),
      identity: ConfettiModifier(color: color, size: size)
    )
  }
}

private struct ConfettiDemoView: View {
  @State private var isFavorite = false

  var body: some View {
    VStack(spacing: 60) {
      ForEach([Font.body, Font.largeTitle, Font.system(size: 72)], id: \.self) { font in
        Button {
          isFavorite.toggle()
        } label: {
          if isFavorite {
            Image(systemName: "star.fill")
              .foregroundStyle(Utils.favoriteColor)
              .transition(.confetti(color: Utils.favoriteColor, size: 3))
          } else {
            Image(systemName: "star")
              .foregroundStyle(.gray)
          }
        }
        .font(font)
      }
    }
  }

  let gradient: any ShapeStyle = .angularGradient(
    colors: [.red, .yellow, .green, .blue, .purple, .red],
    center: .center,
    startAngle: .zero,
    endAngle: .degrees(360)
  )
}

#Preview {
  ConfettiDemoView()
}
