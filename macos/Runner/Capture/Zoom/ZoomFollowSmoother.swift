import CoreGraphics
import Foundation

enum ZoomFollowSmoother {
  static let minStrength: CGFloat = 0.05
  static let maxStrength: CGFloat = 0.50
  static let defaultStrength: CGFloat = 0.15

  static let minDtSeconds: Double = 1.0 / 240.0
  static let maxDtSeconds: Double = 1.0 / 15.0
  static let defaultReferenceFPS: Double = 60.0

  static func clampedFollowStrength(_ value: CGFloat) -> CGFloat {
    let source = value.isFinite ? value : defaultStrength
    return min(max(source, minStrength), maxStrength)
  }

  static func alpha(
    baseStrength: CGFloat,
    dt: Double,
    referenceFPS: Double = defaultReferenceFPS
  ) -> CGFloat {
    let strength = Double(clampedFollowStrength(baseStrength))
    let clampedDt = clampedDtSeconds(dt)
    let safeReferenceFPS =
      (referenceFPS.isFinite && referenceFPS > 0) ? referenceFPS : defaultReferenceFPS
    let normalizedFrames = clampedDt * safeReferenceFPS
    let alphaValue = 1.0 - pow(1.0 - strength, normalizedFrames)
    return CGFloat(min(max(alphaValue, 0.0), 1.0))
  }

  static func lerp(current: CGFloat, target: CGFloat, alpha: CGFloat) -> CGFloat {
    let clampedAlpha = min(max(alpha.isFinite ? alpha : 0, 0), 1)
    return current + (target - current) * clampedAlpha
  }

  static func clampedDtSeconds(_ value: Double) -> Double {
    let source = value.isFinite ? value : (1.0 / defaultReferenceFPS)
    return min(max(source, minDtSeconds), maxDtSeconds)
  }
}

enum ZoomFollowParityDebug {
  private static let envValue: String =
    ProcessInfo.processInfo.environment["CLINGFY_ZOOM_PARITY_DEBUG"] ?? ""

  static let enabled: Bool = {
    let normalized = envValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return normalized == "1" || normalized == "true" || normalized == "yes"
  }()

  static func shouldLogPreview(tick: Int) -> Bool {
    enabled && tick % 30 == 0
  }

  static func shouldLogExport(frameIndex: Int) -> Bool {
    enabled && frameIndex % 30 == 0
  }

  static func logSample(
    source: String,
    time: Double,
    zoom: CGFloat,
    centerX: CGFloat,
    centerY: CGFloat,
    targetZoom: CGFloat,
    targetCenterX: CGFloat,
    targetCenterY: CGFloat
  ) {
    guard enabled else { return }
    NativeLogger.d(
      "ZoomParity",
      "Zoom follow sample",
      context: [
        "source": source,
        "time": time,
        "zoom": zoom,
        "centerX": centerX,
        "centerY": centerY,
        "targetZoom": targetZoom,
        "targetCenterX": targetCenterX,
        "targetCenterY": targetCenterY,
      ]
    )
  }
}
