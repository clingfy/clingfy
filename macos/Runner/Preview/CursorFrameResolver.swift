import Foundation

final class CursorFrameResolver {
  private var frames: [CursorFrame] = []
  private var lastIndex: Int = 0
  private var lastTime: Double = 0

  func reset(with recording: CursorRecording?) {
    frames = recording?.frames ?? []
    lastIndex = 0
    lastTime = 0
  }

  func clear() {
    frames = []
    lastIndex = 0
    lastTime = 0
  }

  func frame(at time: Double) -> CursorFrame? {
    guard !frames.isEmpty else { return nil }

    if time < frames[0].t {
      lastTime = time
      lastIndex = 0
      return nil
    }

    if time >= lastTime, lastIndex < frames.count {
      while lastIndex + 1 < frames.count, frames[lastIndex + 1].t <= time {
        lastIndex += 1
      }
      lastTime = time
      return frames[lastIndex]
    }

    var low = 0
    var high = frames.count - 1
    var resolvedIndex = 0

    while low <= high {
      let mid = (low + high) / 2
      if frames[mid].t <= time {
        resolvedIndex = mid
        low = mid + 1
      } else {
        high = mid - 1
      }
    }

    lastIndex = resolvedIndex
    lastTime = time
    return frames[resolvedIndex]
  }
}
