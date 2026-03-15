import XCTest

@testable import Clingfy

final class CursorFrameResolverTests: XCTestCase {
  private func makeRecording() -> CursorRecording {
    CursorRecording(
      sprites: [],
      frames: [
        CursorFrame(t: 0.1, x: 0.1, y: 0.1, spriteID: 1),
        CursorFrame(t: 0.4, x: 0.4, y: 0.4, spriteID: 2),
        CursorFrame(t: 0.8, x: 0.8, y: 0.8, spriteID: 3),
      ]
    )
  }

  func testForwardPlaybackAdvancesIncrementally() {
    let resolver = CursorFrameResolver()
    resolver.reset(with: makeRecording())

    XCTAssertEqual(resolver.frame(at: 0.15)?.spriteID, 1)
    XCTAssertEqual(resolver.frame(at: 0.45)?.spriteID, 2)
    XCTAssertEqual(resolver.frame(at: 0.85)?.spriteID, 3)
  }

  func testBackwardSeekUsesEarlierFrame() {
    let resolver = CursorFrameResolver()
    resolver.reset(with: makeRecording())

    XCTAssertEqual(resolver.frame(at: 0.85)?.spriteID, 3)
    XCTAssertEqual(resolver.frame(at: 0.2)?.spriteID, 1)
    XCTAssertEqual(resolver.frame(at: 0.5)?.spriteID, 2)
  }

  func testBeforeFirstFrameReturnsNilAndAfterLastReturnsFinalFrame() {
    let resolver = CursorFrameResolver()
    resolver.reset(with: makeRecording())

    XCTAssertNil(resolver.frame(at: 0.01))
    XCTAssertEqual(resolver.frame(at: 2.0)?.spriteID, 3)
  }

  func testClearAndResetResetCachedState() {
    let resolver = CursorFrameResolver()
    resolver.reset(with: makeRecording())
    XCTAssertEqual(resolver.frame(at: 0.45)?.spriteID, 2)

    resolver.clear()
    XCTAssertNil(resolver.frame(at: 0.45))

    resolver.reset(with: makeRecording())
    XCTAssertEqual(resolver.frame(at: 0.15)?.spriteID, 1)
  }
}
