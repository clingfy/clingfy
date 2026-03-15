import CoreGraphics
import XCTest

@testable import Clingfy

final class CameraOverlayShapeTests: XCTestCase {
  private let defaults = UserDefaults.standard
  private let legacyShapeKey = "overlayShape"

  override func setUp() {
    super.setUp()
    clearShapePreferences()
  }

  override func tearDown() {
    clearShapePreferences()
    super.tearDown()
  }

  func testOverlayShapeDefaultsToSquircle() {
    let store = PreferencesStore()

    XCTAssertEqual(store.overlayShape, .squircle)
  }

  func testLegacyOverlayShapeMigratesCircleToStableKey() {
    defaults.set(0, forKey: legacyShapeKey)

    let store = PreferencesStore()

    XCTAssertEqual(store.overlayShape, .circle)
    XCTAssertEqual(storedStableShapeID(), 0)
  }

  func testLegacyOverlayShapeMigratesStarToStableKey() {
    defaults.set(4, forKey: legacyShapeKey)

    let store = PreferencesStore()

    XCTAssertEqual(store.overlayShape, .star)
    XCTAssertEqual(storedStableShapeID(), 4)
  }

  func testInvalidStableShapeFallsBackToSquircleAndRepairsValue() {
    defaults.set(99, forKey: PrefKey.overlayShapeId)

    let store = PreferencesStore()

    XCTAssertEqual(store.overlayShape, .squircle)
    XCTAssertEqual(storedStableShapeID(), CameraOverlayShapeID.defaultValue.rawValue)
  }

  func testSquirclePathIsNonEmptyAndMatchesBounds() {
    let overlay = CameraOverlay()
    let rect = CGRect(x: 10, y: 20, width: 220, height: 160)

    let path = overlay.createSquirclePath(in: rect)

    XCTAssertFalse(path.isEmpty)
    XCTAssertEqual(path.boundingBoxOfPath.minX, rect.minX, accuracy: 0.001)
    XCTAssertEqual(path.boundingBoxOfPath.minY, rect.minY, accuracy: 0.001)
    XCTAssertEqual(path.boundingBoxOfPath.maxX, rect.maxX, accuracy: 0.001)
    XCTAssertEqual(path.boundingBoxOfPath.maxY, rect.maxY, accuracy: 0.001)
  }

  func testSquircleDispatchIsDistinctFromRoundedRectDispatch() {
    let overlay = CameraOverlay()
    overlay.roundness = 0.18
    let rect = CGRect(x: 0, y: 0, width: 220, height: 220)

    let squirclePath = overlay.getPath(for: .squircle, rect: rect)
    let roundedRectPath = overlay.getPath(for: .roundedRect, rect: rect)

    XCTAssertNotEqual(pathElementCount(squirclePath), pathElementCount(roundedRectPath))
  }

  private func clearShapePreferences() {
    defaults.removeObject(forKey: PrefKey.overlayShapeId)
    defaults.removeObject(forKey: legacyShapeKey)
  }

  private func storedStableShapeID() -> Int? {
    (defaults.object(forKey: PrefKey.overlayShapeId) as? NSNumber)?.intValue
  }

  private func pathElementCount(_ path: CGPath) -> Int {
    var count = 0
    path.applyWithBlock { _ in
      count += 1
    }
    return count
  }
}
