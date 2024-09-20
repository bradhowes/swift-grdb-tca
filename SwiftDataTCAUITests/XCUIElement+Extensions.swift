import XCTest

extension XCUIElement {

  func gentleSwipeLeft() {
    let startPoint = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let endPoint = self.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.5))
    startPoint.press(forDuration: 0.2, thenDragTo: endPoint)
  }
}
