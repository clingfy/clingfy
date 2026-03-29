import CoreGraphics
import Foundation

struct RecordingMetadata: Codable {
  struct CropRectInfo: Codable, Equatable {
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

  struct Dimensions: Codable, Equatable {
    let width: Int
    let height: Int
  }

  struct NormalizedPoint: Codable, Equatable {
    let x: Double
    let y: Double
  }

  struct ScreenCaptureInfo: Codable, Equatable {
    let rawRelativePath: String
    let displayMode: Int
    let displayId: UInt32
    let windowId: UInt32?
    let cropRect: CropRectInfo?
    let frameRate: Int
    let quality: String
    let cursorEnabled: Bool
    let cursorLinked: Bool
    let excludedRecorderApp: Bool
  }

  struct CameraCaptureInfo: Codable, Equatable {
    let mode: CameraCaptureMode
    let enabled: Bool
    let rawRelativePath: String?
    let metadataRelativePath: String?
    let deviceId: String?
    let mirroredRaw: Bool
    let nominalFrameRate: Double?
    let dimensions: Dimensions?
    let segments: [CameraRecordingMetadata.Segment]
  }

  struct EditorSeed: Codable, Equatable {
    var cameraVisible: Bool
    var cameraLayoutPreset: CameraLayoutPreset
    var cameraNormalizedCenter: NormalizedPoint?
    var cameraSizeFactor: Double
    var cameraShape: CameraShape
    var cameraCornerRadius: Double
    var cameraBorderWidth: Double
    var cameraBorderColorArgb: Int?
    var cameraShadow: Int
    var cameraOpacity: Double
    var cameraMirror: Bool
    var cameraContentMode: CameraContentMode
    var cameraZoomBehavior: CameraZoomBehavior
    var cameraZoomScaleMultiplier: Double
    var cameraIntroPreset: CameraIntroPreset
    var cameraOutroPreset: CameraOutroPreset
    var cameraZoomEmphasisPreset: CameraZoomEmphasisPreset
    var cameraIntroDurationMs: Int
    var cameraOutroDurationMs: Int
    var cameraZoomEmphasisStrength: Double
    var cameraChromaKeyEnabled: Bool
    var cameraChromaKeyStrength: Double
    var cameraChromaKeyColorArgb: Int?

    init(
      cameraVisible: Bool,
      cameraLayoutPreset: CameraLayoutPreset,
      cameraNormalizedCenter: NormalizedPoint?,
      cameraSizeFactor: Double,
      cameraShape: CameraShape,
      cameraCornerRadius: Double,
      cameraBorderWidth: Double,
      cameraBorderColorArgb: Int?,
      cameraShadow: Int,
      cameraOpacity: Double,
      cameraMirror: Bool,
      cameraContentMode: CameraContentMode,
      cameraZoomBehavior: CameraZoomBehavior,
      cameraZoomScaleMultiplier: Double = 0.35,
      cameraIntroPreset: CameraIntroPreset = .none,
      cameraOutroPreset: CameraOutroPreset = .none,
      cameraZoomEmphasisPreset: CameraZoomEmphasisPreset = .none,
      cameraIntroDurationMs: Int = CameraCompositionParams.defaultIntroDurationMs,
      cameraOutroDurationMs: Int = CameraCompositionParams.defaultOutroDurationMs,
      cameraZoomEmphasisStrength: Double = CameraCompositionParams.defaultZoomEmphasisStrength,
      cameraChromaKeyEnabled: Bool,
      cameraChromaKeyStrength: Double,
      cameraChromaKeyColorArgb: Int?
    ) {
      self.cameraVisible = cameraVisible
      self.cameraLayoutPreset = cameraLayoutPreset
      self.cameraNormalizedCenter = cameraNormalizedCenter
      self.cameraSizeFactor = cameraSizeFactor
      self.cameraShape = cameraShape
      self.cameraCornerRadius = cameraCornerRadius
      self.cameraBorderWidth = cameraBorderWidth
      self.cameraBorderColorArgb = cameraBorderColorArgb
      self.cameraShadow = cameraShadow
      self.cameraOpacity = cameraOpacity
      self.cameraMirror = cameraMirror
      self.cameraContentMode = cameraContentMode
      self.cameraZoomBehavior = cameraZoomBehavior
      self.cameraZoomScaleMultiplier = cameraZoomScaleMultiplier
      self.cameraIntroPreset = cameraIntroPreset
      self.cameraOutroPreset = cameraOutroPreset
      self.cameraZoomEmphasisPreset = cameraZoomEmphasisPreset
      self.cameraIntroDurationMs = cameraIntroDurationMs
      self.cameraOutroDurationMs = cameraOutroDurationMs
      self.cameraZoomEmphasisStrength = cameraZoomEmphasisStrength
      self.cameraChromaKeyEnabled = cameraChromaKeyEnabled
      self.cameraChromaKeyStrength = cameraChromaKeyStrength
      self.cameraChromaKeyColorArgb = cameraChromaKeyColorArgb
    }

    private enum CodingKeys: String, CodingKey {
      case cameraVisible
      case cameraLayoutPreset
      case cameraNormalizedCenter
      case cameraSizeFactor
      case cameraShape
      case cameraCornerRadius
      case cameraBorderWidth
      case cameraBorderColorArgb
      case cameraShadow
      case cameraOpacity
      case cameraMirror
      case cameraContentMode
      case cameraZoomBehavior
      case cameraZoomScaleMultiplier
      case cameraIntroPreset
      case cameraOutroPreset
      case cameraZoomEmphasisPreset
      case cameraIntroDurationMs
      case cameraOutroDurationMs
      case cameraZoomEmphasisStrength
      case cameraChromaKeyEnabled
      case cameraChromaKeyStrength
      case cameraChromaKeyColorArgb
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      cameraVisible = try container.decode(Bool.self, forKey: .cameraVisible)
      cameraLayoutPreset = try container.decode(CameraLayoutPreset.self, forKey: .cameraLayoutPreset)
      cameraNormalizedCenter = try container.decodeIfPresent(
        NormalizedPoint.self,
        forKey: .cameraNormalizedCenter
      )
      cameraSizeFactor = try container.decode(Double.self, forKey: .cameraSizeFactor)
      cameraShape = try container.decode(CameraShape.self, forKey: .cameraShape)
      cameraCornerRadius = try container.decode(Double.self, forKey: .cameraCornerRadius)
      cameraBorderWidth = try container.decode(Double.self, forKey: .cameraBorderWidth)
      cameraBorderColorArgb = try container.decodeIfPresent(Int.self, forKey: .cameraBorderColorArgb)
      cameraShadow = try container.decode(Int.self, forKey: .cameraShadow)
      cameraOpacity = try container.decode(Double.self, forKey: .cameraOpacity)
      cameraMirror = try container.decode(Bool.self, forKey: .cameraMirror)
      cameraContentMode = try container.decode(CameraContentMode.self, forKey: .cameraContentMode)
      cameraZoomBehavior = CameraZoomBehavior.from(
        rawValue: try container.decodeIfPresent(String.self, forKey: .cameraZoomBehavior)
      )
      cameraZoomScaleMultiplier = try container.decodeIfPresent(
        Double.self,
        forKey: .cameraZoomScaleMultiplier
      ) ?? 0.35
      cameraIntroPreset = CameraIntroPreset.from(
        rawValue: try container.decodeIfPresent(String.self, forKey: .cameraIntroPreset)
      )
      cameraOutroPreset = CameraOutroPreset.from(
        rawValue: try container.decodeIfPresent(String.self, forKey: .cameraOutroPreset)
      )
      cameraZoomEmphasisPreset = CameraZoomEmphasisPreset.from(
        rawValue: try container.decodeIfPresent(String.self, forKey: .cameraZoomEmphasisPreset)
      )
      cameraIntroDurationMs = try container.decodeIfPresent(
        Int.self,
        forKey: .cameraIntroDurationMs
      ) ?? CameraCompositionParams.defaultIntroDurationMs
      cameraOutroDurationMs = try container.decodeIfPresent(
        Int.self,
        forKey: .cameraOutroDurationMs
      ) ?? CameraCompositionParams.defaultOutroDurationMs
      cameraZoomEmphasisStrength = try container.decodeIfPresent(
        Double.self,
        forKey: .cameraZoomEmphasisStrength
      ) ?? CameraCompositionParams.defaultZoomEmphasisStrength
      cameraChromaKeyEnabled = try container.decode(Bool.self, forKey: .cameraChromaKeyEnabled)
      cameraChromaKeyStrength = try container.decode(Double.self, forKey: .cameraChromaKeyStrength)
      cameraChromaKeyColorArgb = try container.decodeIfPresent(
        Int.self,
        forKey: .cameraChromaKeyColorArgb
      )
    }
  }

  let version: Int
  let recordingId: String
  let appVersion: String
  let bundleId: String
  let startedAt: String
  var endedAt: String?
  let screen: ScreenCaptureInfo
  var camera: CameraCaptureInfo?
  var editorSeed: EditorSeed

  static func create(
    rawURL: URL,
    displayMode: DisplayTargetMode,
    displayID: CGDirectDisplayID,
    cropRect: CGRect?,
    frameRate: Int,
    quality: RecordingQuality,
    cursorEnabled: Bool,
    cursorLinked: Bool,
    windowID: CGWindowID?,
    excludedRecorderApp: Bool,
    camera: CameraCaptureInfo?,
    editorSeed: EditorSeed
  ) -> RecordingMetadata {
    RecordingMetadata(
      version: 2,
      recordingId: UUID().uuidString,
      appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
      bundleId: Bundle.main.bundleIdentifier ?? "com.clingfy.app",
      startedAt: recordingISO8601String(from: Date()),
      endedAt: nil,
      screen: ScreenCaptureInfo(
        rawRelativePath: rawURL.lastPathComponent,
        displayMode: displayMode.rawValue,
        displayId: displayID,
        windowId: windowID.map { UInt32($0) },
        cropRect: cropRect.map { CropRectInfo(rect: $0) },
        frameRate: frameRate,
        quality: quality.rawValue,
        cursorEnabled: cursorEnabled,
        cursorLinked: cursorLinked,
        excludedRecorderApp: excludedRecorderApp
      ),
      camera: camera,
      editorSeed: editorSeed
    )
  }

  func write(to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(self)
    try data.write(to: url)
  }

  static func read(from url: URL) throws -> RecordingMetadata {
    let data = try Data(contentsOf: url)
    let object = try JSONSerialization.jsonObject(with: data)
    guard let dictionary = object as? [String: Any] else {
      throw flutterError(NativeErrorCode.recordingError, "Recording metadata is not a dictionary")
    }

    if dictionary["version"] != nil || dictionary["screen"] != nil {
      return try JSONDecoder().decode(RecordingMetadata.self, from: data)
    }

    let legacy = try JSONDecoder().decode(LegacyRecordingMetadataV1.self, from: data)
    return RecordingMetadata(legacy: legacy, metadataURL: url)
  }

  func withEndTimestamp(_ date: Date = Date()) -> RecordingMetadata {
    var copy = self
    copy.endedAt = recordingISO8601String(from: date)
    return copy
  }

  static func iso8601String(from date: Date) -> String {
    recordingISO8601String(from: date)
  }
}

private extension RecordingMetadata {
  init(legacy: LegacyRecordingMetadataV1, metadataURL: URL) {
    let rawRelativePath = Self.rawRelativePath(fromLegacyMetadataURL: metadataURL)
    self.init(
      version: 2,
      recordingId: UUID().uuidString,
      appVersion: legacy.appVersion,
      bundleId: legacy.bundleId,
      startedAt: legacy.startedAt,
      endedAt: legacy.endedAt,
      screen: ScreenCaptureInfo(
        rawRelativePath: rawRelativePath,
        displayMode: legacy.displayMode,
        displayId: legacy.displayID,
        windowId: legacy.windowID,
        cropRect: legacy.cropRect,
        frameRate: legacy.frameRate,
        quality: legacy.quality,
        cursorEnabled: legacy.cursorEnabled,
        cursorLinked: legacy.cursorLinked,
        excludedRecorderApp: legacy.excludedRecorderApp
      ),
      camera: nil,
      editorSeed: EditorSeed(
        cameraVisible: legacy.overlayEnabled,
        cameraLayoutPreset: .overlayBottomRight,
        cameraNormalizedCenter: nil,
        cameraSizeFactor: 0.18,
        cameraShape: .circle,
        cameraCornerRadius: 0.0,
        cameraBorderWidth: 4.0,
        cameraBorderColorArgb: nil,
        cameraShadow: 0,
        cameraOpacity: 1.0,
        cameraMirror: true,
        cameraContentMode: .fill,
        cameraZoomBehavior: .fixed,
        cameraZoomScaleMultiplier: 0.35,
        cameraIntroPreset: .none,
        cameraOutroPreset: .none,
        cameraZoomEmphasisPreset: .none,
        cameraIntroDurationMs: CameraCompositionParams.defaultIntroDurationMs,
        cameraOutroDurationMs: CameraCompositionParams.defaultOutroDurationMs,
        cameraZoomEmphasisStrength: CameraCompositionParams.defaultZoomEmphasisStrength,
        cameraChromaKeyEnabled: false,
        cameraChromaKeyStrength: 0.4,
        cameraChromaKeyColorArgb: nil
      )
    )
  }

  static func rawRelativePath(fromLegacyMetadataURL url: URL) -> String {
    let fileName = url.lastPathComponent
    if fileName.hasSuffix(".meta.json") {
      let trimmed = String(fileName.dropLast(".meta.json".count))
      return "\(trimmed).mov"
    }
    return url.deletingPathExtension().lastPathComponent
  }
}

private struct LegacyRecordingMetadataV1: Codable {
  let schemaVersion: Int
  let appVersion: String
  let bundleId: String
  let startedAt: String
  let endedAt: String?
  let displayMode: Int
  let displayID: UInt32
  let cropRect: RecordingMetadata.CropRectInfo?
  let frameRate: Int
  let quality: String
  let cursorEnabled: Bool
  let cursorLinked: Bool
  let overlayEnabled: Bool
  let windowID: UInt32?
  let excludedRecorderApp: Bool
}

private func iso8601String(from date: Date) -> String {
  recordingISO8601String(from: date)
}

private func recordingISO8601String(from date: Date) -> String {
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  return formatter.string(from: date)
}
