import SwiftUI

struct ZebraStripeRenderer: TextRenderer {
  func draw(layout: Text.Layout, in context: inout GraphicsContext) {
    for (index, line) in layout.enumerated() {
      if index.isMultiple(of: 2) {
        context.opacity = 1
      } else {
        context.opacity = 0.5
      }

      context.draw(line)
    }
  }
}

struct Demo1View: View {
  var body: some View {
    Text("He thrusts his fists against the posts and still insists he sees the ghosts.")
      .font(.largeTitle)
      .textRenderer(ZebraStripeRenderer())
  }
}

#Preview("Demo1") {
  Demo1View()
}

struct BoxedRenderer: TextRenderer {
  func draw(layout: Text.Layout, in context: inout GraphicsContext) {
    for line in layout {
      for run in line {
        for glyph in run {
          context.stroke(Rectangle().path(in: glyph.typographicBounds.rect), with: .color(.blue), lineWidth: 2)
        }

        context.stroke(Rectangle().path(in: run.typographicBounds.rect), with: .color(.green), lineWidth: 2)
      }

      context.stroke(Rectangle().path(in: line.typographicBounds.rect), with: .color(.red), lineWidth: 2)

      context.draw(line)
    }
  }
}

struct Demo2View: View {
  var body: some View {
    VStack {
      (
        Text("This is a **very** important string") +
        Text(" with lots of text inside.")
          .foregroundStyle(.secondary)
      )
      .font(.largeTitle)
      .textRenderer(BoxedRenderer())
    }
  }
}

#Preview("Demo2") {
  Demo2View()
}

struct Demo3View: View {
  @State private var textFrame = CGRect.zero
  @State private var textSize = 17.0

  var body: some View {
    VStack {
      Text("Hello, world")
        .font(.system(size: textSize))
        .onGeometryChange(for: CGRect.self) { proxy in
          proxy.frame(in: .global)
        } action: { newValue in
          textFrame = newValue
        }

      Rectangle()
        .frame(width: textFrame.width, height: textFrame.height)

      Slider(value: $textSize, in: 10...30)
        .padding()
    }
  }
}

#Preview("Demo3") {
  Demo3View()
}
