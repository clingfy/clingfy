import CoreGraphics
import Foundation

struct PreviewProfile: Equatable {
  let canvasRenderSize: CGSize
  let renderScale: CGFloat
  let fps: Int32
  let maxLongEdge: CGFloat

  static let defaultMaxLongEdge: CGFloat = 1440
  static let defaultFps: Int32 = 30

  static func make(
    viewBounds: CGSize,
    backingScale: CGFloat,
    targetSize: CGSize,
    fpsHint: Int32,
    maxLongEdge: CGFloat = PreviewProfile.defaultMaxLongEdge
  ) -> PreviewProfile {
    let normalizedTarget = normalizedSize(targetSize)
    let cappedCanvas = previewCanvasPixelSize(
      for: normalizedTarget,
      in: viewBounds,
      backingScale: backingScale,
      maxLongEdge: maxLongEdge
    )

    let widthScale = cappedCanvas.width / max(normalizedTarget.width, 1)
    let heightScale = cappedCanvas.height / max(normalizedTarget.height, 1)
    let renderScale = max(0.0001, min(widthScale, heightScale))

    let fps: Int32
    if fpsHint > 0 {
      fps = min(fpsHint, PreviewProfile.defaultFps)
    } else {
      fps = PreviewProfile.defaultFps
    }

    return PreviewProfile(
      canvasRenderSize: cappedCanvas,
      renderScale: renderScale,
      fps: fps,
      maxLongEdge: maxLongEdge
    )
  }

  private static func normalizedSize(_ size: CGSize) -> CGSize {
    CGSize(width: max(1, size.width), height: max(1, size.height))
  }

  private static func previewCanvasPixelSize(
    for targetSize: CGSize,
    in viewBounds: CGSize,
    backingScale: CGFloat,
    maxLongEdge: CGFloat
  ) -> CGSize {
    let normalizedTarget = normalizedSize(targetSize)
    let safeBackingScale = backingScale > 0 ? backingScale : 2.0
    let longEdgeCap = max(1, maxLongEdge)

    let fittedSize: CGSize
    if viewBounds.width > 0, viewBounds.height > 0 {
      let fitScale = min(
        viewBounds.width / normalizedTarget.width,
        viewBounds.height / normalizedTarget.height
      )
      fittedSize = CGSize(
        width: normalizedTarget.width * fitScale * safeBackingScale,
        height: normalizedTarget.height * fitScale * safeBackingScale
      )
    } else {
      let fallbackScale = longEdgeCap / max(normalizedTarget.width, normalizedTarget.height)
      fittedSize = CGSize(
        width: normalizedTarget.width * fallbackScale,
        height: normalizedTarget.height * fallbackScale
      )
    }

    return aspectFit(fittedSize, maxLongEdge: longEdgeCap)
  }

  private static func aspectFit(_ size: CGSize, maxLongEdge: CGFloat) -> CGSize {
    let normalized = normalizedSize(size)
    let currentLongEdge = max(normalized.width, normalized.height)
    let scale = currentLongEdge > maxLongEdge ? maxLongEdge / currentLongEdge : 1.0

    return CGSize(
      width: max(1, (normalized.width * scale).rounded()),
      height: max(1, (normalized.height * scale).rounded())
    )
  }
}
