import GRDB
import SwiftUI


struct AnimatedScheduler: ValueObservationScheduler {
  let animation: Animation?

  func immediateInitialValue() -> Bool { true }

  func schedule(_ action: @escaping @Sendable () -> Void) {
    if let animation {
      DispatchQueue.main.async {
        withAnimation(animation) {
          action()
        }
      }
    } else {
      DispatchQueue.main.async(execute: action)
    }
  }
}

extension ValueObservationScheduler where Self == AnimatedScheduler {
  static func animation(_ animation: Animation?) -> Self {
    AnimatedScheduler(animation: animation)
  }
}
