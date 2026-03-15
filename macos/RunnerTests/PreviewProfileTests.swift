import CoreGraphics
import Foundation
import XCTest

@testable import Clingfy

final class PreviewProfileTests: XCTestCase {
  func testFourKTargetUsesViewportSizedCanvasAndCap() {
    let profile = PreviewProfile.make(
      viewBounds: CGSize(width: 800, height: 450),
      backingScale: 2.0,
      targetSize: CGSize(width: 3840, height: 2160),
      fpsHint: 60
    )

    XCTAssertEqual(profile.canvasRenderSize.width, 1440)
    XCTAssertEqual(profile.canvasRenderSize.height, 810)
    XCTAssertEqual(profile.fps, 30)
    XCTAssertLessThanOrEqual(max(profile.canvasRenderSize.width, profile.canvasRenderSize.height), 1440)
  }

  func testSmallViewportDoesNotInflateToExportSize() {
    let profile = PreviewProfile.make(
      viewBounds: CGSize(width: 320, height: 180),
      backingScale: 2.0,
      targetSize: CGSize(width: 3840, height: 2160),
      fpsHint: 30
    )

    XCTAssertEqual(profile.canvasRenderSize.width, 640)
    XCTAssertEqual(profile.canvasRenderSize.height, 360)
    XCTAssertEqual(profile.fps, 30)
  }

  func testLowerFpsHintIsPreserved() {
    let profile = PreviewProfile.make(
      viewBounds: CGSize(width: 1200, height: 675),
      backingScale: 2.0,
      targetSize: CGSize(width: 1920, height: 1080),
      fpsHint: 24
    )

    XCTAssertEqual(profile.fps, 24)
  }

  func testInvalidBoundsFallBackToAspectFittedTargetCap() {
    let profile = PreviewProfile.make(
      viewBounds: .zero,
      backingScale: 0,
      targetSize: CGSize(width: 3840, height: 2160),
      fpsHint: 0
    )

    XCTAssertEqual(profile.canvasRenderSize.width, 1440)
    XCTAssertEqual(profile.canvasRenderSize.height, 810)
    XCTAssertEqual(profile.fps, 30)
  }
}

final class InlinePreviewViewLifecycleTests: XCTestCase {
  func testPreviewLifecyclePayloadIncludesSessionId() {
    let token = UUID()
    let payload = InlinePreviewView.previewLifecycleEventPayload(
      type: "previewReady",
      sessionId: "rec_session_1",
      path: "/tmp/test.mov",
      token: token,
      reason: "ready",
      error: nil
    )

    XCTAssertEqual(payload["type"] as? String, "previewReady")
    XCTAssertEqual(payload["sessionId"] as? String, "rec_session_1")
    XCTAssertEqual(payload["path"] as? String, "/tmp/test.mov")
    XCTAssertEqual(payload["token"] as? String, token.uuidString)
    XCTAssertEqual(payload["reason"] as? String, "ready")
  }

  func testPreviewReadyGateRequiresInitialCompositionToBeApplied() {
    XCTAssertFalse(
      InlinePreviewView.canEmitPreviewReady(
        hasEmittedReady: false,
        tokenMatches: true,
        itemReady: true,
        layerReady: true,
        initialCompositionApplied: false
      ))

    XCTAssertFalse(
      InlinePreviewView.canEmitPreviewReady(
        hasEmittedReady: false,
        tokenMatches: true,
        itemReady: false,
        layerReady: true,
        initialCompositionApplied: true
      ))

    XCTAssertTrue(
      InlinePreviewView.canEmitPreviewReady(
        hasEmittedReady: false,
        tokenMatches: true,
        itemReady: true,
        layerReady: true,
        initialCompositionApplied: true
      ))
  }
}
