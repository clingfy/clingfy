import Foundation

class ZoomHysteresis {
  let zoomInDelay: Double = 0.2
  let zoomOutDelay: Double = 0.3
  let minZoomOnDuration: Double = 0.30

  private(set) var stableZoomActive: Bool = false
  private var lastRaw: Bool = false
  private var rawChangedAt: Double = 0
  private var zoomTurnedOnAt: Double = 0

  func update(time: Double, rawZoomWanted raw: Bool) -> Bool {
    // If raw changes: update tracking
    if raw != lastRaw {
      rawChangedAt = time
      lastRaw = raw
    }

    // If stable state doesn't match raw, check if we can transition
    if stableZoomActive != raw {
      let delay = raw ? zoomInDelay : zoomOutDelay

      if (time - rawChangedAt) >= delay {
        if !raw {
          // Turning OFF
          if (time - zoomTurnedOnAt) >= minZoomOnDuration {
            stableZoomActive = false
          }
        } else {
          // Turning ON
          stableZoomActive = true
          zoomTurnedOnAt = time
        }
      }
    }

    return stableZoomActive
  }

  func reset() {
    stableZoomActive = false
    lastRaw = false
    rawChangedAt = 0
    zoomTurnedOnAt = 0
  }
}
