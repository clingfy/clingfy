import Foundation
import CoreGraphics

/// Metadata stored alongside raw recordings for recovery and diagnostics.
///
/// This file is written as `.meta.json` next to the raw `.mov` recording
/// in the internal workspace.
struct RecordingMetadata: Codable {
  /// Schema version for forward compatibility
  let schemaVersion: Int

  /// App version that created this recording
  let appVersion: String

  /// Bundle identifier
  let bundleId: String

  /// Recording start timestamp (ISO 8601)
  let startedAt: String

  /// Recording end timestamp (ISO 8601), nil if recording was interrupted
  var endedAt: String?

  /// Display target mode (explicitID, appWindow, singleAppWindow, areaRecording, etc.)
  let displayMode: Int

  /// Target display ID
  let displayID: UInt32

  /// Crop rectangle if applicable (for area/window recording)
  let cropRect: CropRectInfo?

  /// Frame rate used for capture
  let frameRate: Int

  /// Recording quality setting
  let quality: String

  /// Whether cursor recording was enabled
  let cursorEnabled: Bool

  /// Whether cursor was linked to recording
  let cursorLinked: Bool

  /// Whether camera overlay was enabled
  let overlayEnabled: Bool

  /// Window ID if recording a specific app window
  let windowID: UInt32?

  /// Whether the recorder app was excluded from capture.
  /// When true, cursor recording was disabled and zoom effects should not be applied.
  let excludedRecorderApp: Bool

  /// Nested struct for crop rect serialization
  struct CropRectInfo: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double

    init(rect: CGRect) {
      self.x = rect.origin.x
      self.y = rect.origin.y
      self.width = rect.size.width
      self.height = rect.size.height
    }

    var cgRect: CGRect {
      CGRect(x: x, y: y, width: width, height: height)
    }
  }

  // MARK: - Factory

  /// Creates metadata for a new recording session.
  static func create(
    displayMode: DisplayTargetMode,
    displayID: CGDirectDisplayID,
    cropRect: CGRect?,
    frameRate: Int,
    quality: RecordingQuality,
    cursorEnabled: Bool,
    cursorLinked: Bool,
    overlayEnabled: Bool,
    windowID: CGWindowID?,
    excludedRecorderApp: Bool
  ) -> RecordingMetadata {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    return RecordingMetadata(
      schemaVersion: 1,
      appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
      bundleId: Bundle.main.bundleIdentifier ?? "com.clingfy.app",
      startedAt: formatter.string(from: Date()),
      endedAt: nil,
      displayMode: displayMode.rawValue,
      displayID: displayID,
      cropRect: cropRect.map { CropRectInfo(rect: $0) },
      frameRate: frameRate,
      quality: quality.rawValue,
      cursorEnabled: cursorEnabled,
      cursorLinked: cursorLinked,
      overlayEnabled: overlayEnabled,
      windowID: windowID,
      excludedRecorderApp: excludedRecorderApp
    )
  }

  // MARK: - File Operations

  /// Writes metadata to the given URL.
  func write(to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(self)
    try data.write(to: url)
  }

  /// Reads metadata from the given URL.
  static func read(from url: URL) throws -> RecordingMetadata {
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(RecordingMetadata.self, from: data)
  }

  /// Creates a copy with the endedAt timestamp set to now.
  func withEndTimestamp() -> RecordingMetadata {
    var copy = self
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    copy.endedAt = formatter.string(from: Date())
    return copy
  }
}
