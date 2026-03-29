import AVFoundation
import Cocoa
import FlutterMacOS
import XCTest

@testable import Clingfy

final class AppPathsTests: XCTestCase {
  func testCameraArtifactsUseScreenRecordingStem() {
    let rawURL = URL(fileURLWithPath: "/tmp/recording.mov")

    XCTAssertEqual(AppPaths.cameraRawURL(for: rawURL).lastPathComponent, "recording.camera.mov")
    XCTAssertEqual(
      AppPaths.cameraMetadataSidecarURL(for: rawURL).lastPathComponent,
      "recording.camera.meta.json"
    )
    XCTAssertEqual(
      AppPaths.cameraSegmentDirectoryURL(for: rawURL).lastPathComponent,
      "recording.camera.segments"
    )

    let artifactNames = AppPaths.allRecordingArtifactURLs(for: rawURL).map(\.lastPathComponent)
    XCTAssertEqual(
      artifactNames,
      [
        "recording.mov",
        "recording.cursor.json",
        "recording.meta.json",
        "recording.zoom.manual.json",
        "recording.camera.mov",
        "recording.camera.meta.json",
        "recording.camera.segments",
      ]
    )
  }
}

final class RecordingMetadataTests: XCTestCase {
  func testVersion2RoundTripPreservesCameraAndEditorSeed() throws {
    let tempDir = makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let rawURL = tempDir.appendingPathComponent("recording.mov")
    let metadataURL = AppPaths.metadataSidecarURL(for: rawURL)
    let cameraInfo = RecordingMetadata.CameraCaptureInfo(
      mode: .separateCameraAsset,
      enabled: true,
      rawRelativePath: "recording.camera.mov",
      metadataRelativePath: "recording.camera.meta.json",
      deviceId: "camera-1",
      mirroredRaw: true,
      nominalFrameRate: 30,
      dimensions: .init(width: 1920, height: 1080),
      segments: [
        .init(
          index: 0,
          relativePath: "recording.camera.segments/segment_000.mov",
          startWallClock: RecordingMetadata.iso8601String(from: Date(timeIntervalSince1970: 0)),
          endWallClock: RecordingMetadata.iso8601String(from: Date(timeIntervalSince1970: 5))
        )
      ]
    )
    let editorSeed = RecordingMetadata.EditorSeed(
      cameraVisible: true,
      cameraLayoutPreset: .overlayTopLeft,
      cameraNormalizedCenter: .init(x: 0.4, y: 0.6),
      cameraSizeFactor: 0.22,
      cameraShape: .roundedRect,
      cameraCornerRadius: 0.25,
      cameraBorderWidth: 3.0,
      cameraBorderColorArgb: 0xFFFFFFFF,
      cameraShadow: 1,
      cameraOpacity: 0.8,
      cameraMirror: false,
      cameraContentMode: .fit,
      cameraZoomBehavior: .scaleDownWhenScreenZooms,
      cameraChromaKeyEnabled: true,
      cameraChromaKeyStrength: 0.5,
      cameraChromaKeyColorArgb: 0xFF00FF00
    )
    let metadata = RecordingMetadata.create(
      rawURL: rawURL,
      displayMode: .explicitID,
      displayID: 123,
      cropRect: CGRect(x: 10, y: 20, width: 300, height: 200),
      frameRate: 60,
      quality: .fhd,
      cursorEnabled: true,
      cursorLinked: true,
      windowID: 77,
      excludedRecorderApp: true,
      camera: cameraInfo,
      editorSeed: editorSeed
    )

    try metadata.write(to: metadataURL)
    let decoded = try RecordingMetadata.read(from: metadataURL)

    XCTAssertEqual(decoded.version, 2)
    XCTAssertEqual(decoded.screen.rawRelativePath, "recording.mov")
    XCTAssertEqual(decoded.screen.windowId, 77)
    XCTAssertEqual(decoded.camera, cameraInfo)
    XCTAssertEqual(decoded.editorSeed, editorSeed)
  }

  func testLegacyMetadataReadMigratesToVersion2Schema() throws {
    let tempDir = makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let metadataURL = tempDir.appendingPathComponent("recording.meta.json")
    let legacyJSON = """
      {
        "schemaVersion": 1,
        "appVersion": "1.0.0",
        "bundleId": "com.clingfy.app",
        "startedAt": "2025-01-01T00:00:00.000Z",
        "endedAt": "2025-01-01T00:00:05.000Z",
        "displayMode": 0,
        "displayID": 123,
        "cropRect": {
          "x": 10,
          "y": 20,
          "width": 300,
          "height": 200
        },
        "frameRate": 60,
        "quality": "fhd",
        "cursorEnabled": true,
        "cursorLinked": true,
        "overlayEnabled": true,
        "windowID": 42,
        "excludedRecorderApp": true
      }
      """
    let data = try XCTUnwrap(legacyJSON.data(using: .utf8))
    try data.write(to: metadataURL)

    let decoded = try RecordingMetadata.read(from: metadataURL)

    XCTAssertEqual(decoded.version, 2)
    XCTAssertNil(decoded.camera)
    XCTAssertEqual(decoded.screen.rawRelativePath, "recording.mov")
    XCTAssertEqual(decoded.screen.windowId, 42)
    XCTAssertEqual(decoded.editorSeed.cameraVisible, true)
    XCTAssertEqual(decoded.editorSeed.cameraLayoutPreset, .overlayBottomRight)
  }

  private func makeTemporaryDirectory() -> URL {
    let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try? FileManager.default.createDirectory(
      at: url,
      withIntermediateDirectories: true,
      attributes: nil
    )
    return url
  }
}

final class CameraRecorderTests: XCTestCase {
  func testRecordingStoppedErrorWithSuccessKeyIsTreatedAsSuccessfulFinish() {
    let error = NSError(
      domain: AVFoundationErrorDomain,
      code: AVError.unknown.rawValue,
      userInfo: [
        NSLocalizedDescriptionKey: "Recording Stopped",
        AVErrorRecordingSuccessfullyFinishedKey: true,
      ]
    )

    XCTAssertTrue(CameraRecorder._testRecordingFinishedSuccessfully(error))
  }

  func testRecordingStoppedErrorWithoutSuccessKeyIsTreatedAsFailure() {
    let error = NSError(
      domain: AVFoundationErrorDomain,
      code: AVError.unknown.rawValue,
      userInfo: [
        NSLocalizedDescriptionKey: "Recording Stopped"
      ]
    )

    XCTAssertFalse(CameraRecorder._testRecordingFinishedSuccessfully(error))
  }
}

final class CameraLayoutResolverTests: XCTestCase {
  func testManualFrameClampsIntoCanvasBounds() {
    let params = CameraCompositionParams(
      visible: true,
      layoutPreset: .overlayBottomRight,
      normalizedCanvasCenter: CGPoint(x: 1.2, y: -0.2),
      sizeFactor: 0.3,
      shape: .circle,
      cornerRadius: 0,
      opacity: 1,
      mirror: true,
      contentMode: .fill,
      zoomBehavior: .fixed,
      borderWidth: 0,
      borderColorArgb: nil,
      shadowPreset: 0,
      chromaKeyEnabled: false,
      chromaKeyStrength: 0.4,
      chromaKeyColorArgb: nil
    )

    let resolution = CameraLayoutResolver.effectiveFrame(
      canvasSize: CGSize(width: 1000, height: 600),
      params: params
    )

    XCTAssertTrue(resolution.shouldRender)
    XCTAssertEqual(resolution.zOrder, .aboveScreen)
    XCTAssertEqual(resolution.frame.maxX, 1000, accuracy: 0.001)
    XCTAssertEqual(resolution.frame.minY, 0, accuracy: 0.001)
  }

  func testBackgroundBehindUsesFullCanvasAndHiddenDoesNotRender() {
    var params = CameraCompositionParams.hidden
    params.visible = true
    params.layoutPreset = .backgroundBehind

    let background = CameraLayoutResolver.resolve(
      canvasSize: CGSize(width: 1280, height: 720),
      params: params
    )

    XCTAssertTrue(background.shouldRender)
    XCTAssertEqual(background.zOrder, .behindScreen)
    XCTAssertEqual(background.frame, CGRect(x: 0, y: 0, width: 1280, height: 720))

    let hidden = CameraLayoutResolver.resolve(
      canvasSize: CGSize(width: 1280, height: 720),
      params: .hidden
    )
    XCTAssertFalse(hidden.shouldRender)
    XCTAssertEqual(hidden.frame, .zero)
  }

  func testMaskPathMatchesRequestedShape() {
    let rect = CGRect(x: 0, y: 0, width: 200, height: 120)
    var params = CameraCompositionParams.hidden
    params.visible = true
    params.layoutPreset = .overlayBottomRight
    params.shape = .roundedRect
    params.cornerRadius = 0.25

    let roundedRect = CameraLayoutResolver.maskPath(in: rect, params: params)
    XCTAssertEqual(roundedRect.boundingBox, rect)

    params.shape = .circle
    let circle = CameraLayoutResolver.maskPath(in: rect, params: params)
    XCTAssertEqual(circle.boundingBox, rect)
  }
}

final class LetterboxExporterTests: XCTestCase {
  func testSeparateCameraExportUsesStyledIntermediateForAdvancedStyling() {
    let exporter = LetterboxExporter()
    let params = CameraCompositionParams(
      visible: true,
      layoutPreset: .overlayBottomRight,
      normalizedCanvasCenter: nil,
      sizeFactor: 0.2,
      shape: .circle,
      cornerRadius: 0.0,
      opacity: 0.9,
      mirror: true,
      contentMode: .fill,
      zoomBehavior: .fixed,
      borderWidth: 0.0,
      borderColorArgb: nil,
      shadowPreset: 0,
      chromaKeyEnabled: false,
      chromaKeyStrength: 0.4,
      chromaKeyColorArgb: nil
    )

    XCTAssertTrue(exporter._testShouldUseStyledCameraIntermediate(cameraParams: params))
  }

  func testSeparateCameraExportSkipsStyledIntermediateForGeometryOnlyParams() {
    let exporter = LetterboxExporter()
    let params = CameraCompositionParams(
      visible: true,
      layoutPreset: .overlayBottomRight,
      normalizedCanvasCenter: nil,
      sizeFactor: 0.2,
      shape: .square,
      cornerRadius: 0.0,
      opacity: 0.9,
      mirror: true,
      contentMode: .fill,
      zoomBehavior: .fixed,
      borderWidth: 0.0,
      borderColorArgb: nil,
      shadowPreset: 0,
      chromaKeyEnabled: false,
      chromaKeyStrength: 0.4,
      chromaKeyColorArgb: nil
    )

    XCTAssertFalse(exporter._testShouldUseStyledCameraIntermediate(cameraParams: params))
  }
}

final class ScreenCaptureKitOverlayFilterPolicyTests: XCTestCase {
  func testOverlayWindowExcludedWhenSeparateCameraModeKeepsRecorderVisible() {
    let windows = [
      ScreenCaptureKitOverlayFilterPolicy.WindowRecord(windowID: 11, bundleIdentifier: "com.clingfy.clingfy.dev"),
      ScreenCaptureKitOverlayFilterPolicy.WindowRecord(windowID: 12, bundleIdentifier: "com.apple.finder"),
    ]

    let excluded = ScreenCaptureKitOverlayFilterPolicy.excludedWindowIDs(
      windows: windows,
      selfBundleIdentifier: "com.clingfy.clingfy.dev",
      overlayWindowID: 11,
      excludeRecorderApp: false,
      excludeCameraOverlayWindow: true
    )

    XCTAssertEqual(excluded, [11])
  }

  func testOverlayAndRecorderWindowsExcludedTogetherWhenRecorderAppExcluded() {
    let windows = [
      ScreenCaptureKitOverlayFilterPolicy.WindowRecord(windowID: 11, bundleIdentifier: "com.clingfy.clingfy.dev"),
      ScreenCaptureKitOverlayFilterPolicy.WindowRecord(windowID: 13, bundleIdentifier: "com.clingfy.clingfy.dev"),
      ScreenCaptureKitOverlayFilterPolicy.WindowRecord(windowID: 12, bundleIdentifier: "com.apple.finder"),
    ]

    let excluded = ScreenCaptureKitOverlayFilterPolicy.excludedWindowIDs(
      windows: windows,
      selfBundleIdentifier: "com.clingfy.clingfy.dev",
      overlayWindowID: 11,
      excludeRecorderApp: true,
      excludeCameraOverlayWindow: true
    )

    XCTAssertEqual(excluded, [11, 13])
  }

  func testBakedOverlayKeepsOverlayWindowWhenRecorderAppExcluded() {
    let windows = [
      ScreenCaptureKitOverlayFilterPolicy.WindowRecord(windowID: 11, bundleIdentifier: "com.clingfy.clingfy.dev"),
      ScreenCaptureKitOverlayFilterPolicy.WindowRecord(windowID: 13, bundleIdentifier: "com.clingfy.clingfy.dev"),
      ScreenCaptureKitOverlayFilterPolicy.WindowRecord(windowID: 12, bundleIdentifier: "com.apple.finder"),
    ]

    let excluded = ScreenCaptureKitOverlayFilterPolicy.excludedWindowIDs(
      windows: windows,
      selfBundleIdentifier: "com.clingfy.clingfy.dev",
      overlayWindowID: 11,
      excludeRecorderApp: true,
      excludeCameraOverlayWindow: false
    )

    XCTAssertEqual(excluded, [13])
  }
}

private final class MockCaptureBackend: CaptureBackend {
  var onStarted: ((URL) -> Void)?
  var onFinished: ((URL?, Error?) -> Void)?
  var onPaused: (() -> Void)?
  var onResumed: (() -> Void)?
  var onMicrophoneLevel: ((MicrophoneLevelSample) -> Void)?

  var canPauseResume: Bool = true
  var supportsLiveOverlayExclusionDuringSeparateCameraCapture: Bool = false
  var isRecording: Bool = false
  var isPaused: Bool = false
  var currentOutputURL: URL?
  private(set) var overlayUpdates: [CGWindowID?] = []
  private(set) var stopCallCount: Int = 0

  func start(config: CaptureStartConfig) {}
  func stop() { stopCallCount += 1 }
  func pause() {}
  func resume() {}

  func updateOverlay(windowID: CGWindowID?) {
    overlayUpdates.append(windowID)
  }
}

@MainActor
final class ScreenRecorderFacadeSeparateCameraTests: XCTestCase {
  func testFinishMetadataPublishesFinalCameraBasename() throws {
    let tempDir = makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let publishedScreenURL = tempDir.appendingPathComponent("recording.mov")
    let inProgressScreenURL = tempDir.appendingPathComponent("recording.123.inprogress.mov")
    let metadataURL = AppPaths.metadataSidecarURL(for: inProgressScreenURL)

    let initialMetadata = RecordingMetadata.create(
      rawURL: publishedScreenURL,
      displayMode: .explicitID,
      displayID: 1,
      cropRect: nil,
      frameRate: 60,
      quality: .fhd,
      cursorEnabled: true,
      cursorLinked: true,
      windowID: nil,
      excludedRecorderApp: false,
      camera: RecordingMetadata.CameraCaptureInfo(
        mode: .separateCameraAsset,
        enabled: true,
        rawRelativePath: AppPaths.cameraRawURL(for: publishedScreenURL).lastPathComponent,
        metadataRelativePath: AppPaths.cameraMetadataSidecarURL(for: publishedScreenURL).lastPathComponent,
        deviceId: "camera-1",
        mirroredRaw: true,
        nominalFrameRate: 30,
        dimensions: .init(width: 1920, height: 1080),
        segments: []
      ),
      editorSeed: makeEditorSeed()
    )
    try initialMetadata.write(to: metadataURL)

    let cameraResult = CameraRecordingResult(
      rawURL: AppPaths.cameraRawURL(for: inProgressScreenURL),
      metadataURL: AppPaths.cameraMetadataSidecarURL(for: inProgressScreenURL),
      metadata: CameraRecordingMetadata(
        version: 1,
        recordingId: "camera-recording-id",
        rawRelativePath: AppPaths.cameraRawURL(for: inProgressScreenURL).lastPathComponent,
        metadataRelativePath: AppPaths.cameraMetadataSidecarURL(for: inProgressScreenURL)
          .lastPathComponent,
        deviceId: "camera-1",
        mirroredRaw: true,
        nominalFrameRate: 30,
        dimensions: .init(width: 1920, height: 1080),
        startedAt: RecordingMetadata.iso8601String(from: Date(timeIntervalSince1970: 0)),
        endedAt: RecordingMetadata.iso8601String(from: Date(timeIntervalSince1970: 5)),
        segments: []
      )
    )

    let facade = ScreenRecorderFacade()
    facade._testUpdateMetadataSidecarOnFinish(
      for: inProgressScreenURL,
      cameraResult: cameraResult,
      publishedScreenURL: publishedScreenURL
    )

    let updated = try RecordingMetadata.read(from: metadataURL)
    XCTAssertEqual(updated.camera?.rawRelativePath, "recording.camera.mov")
    XCTAssertEqual(updated.camera?.metadataRelativePath, "recording.camera.meta.json")
    XCTAssertFalse(updated.camera?.rawRelativePath?.contains(".inprogress.") ?? true)
  }

  func testSeparateCameraCaptureConfigRespectsRecorderExclusionPreference() {
    let prefs = PreferencesStore()
    let originalOverlayEnabled = prefs.overlayEnabled
    let originalOverlayLinked = prefs.overlayLinked
    let originalExcludeRecorderApp = prefs.excludeRecorderApp
    let originalCameraCaptureMode = prefs.cameraCaptureMode
    defer {
      prefs.overlayEnabled = originalOverlayEnabled
      prefs.overlayLinked = originalOverlayLinked
      prefs.excludeRecorderApp = originalExcludeRecorderApp
      prefs.cameraCaptureMode = originalCameraCaptureMode
    }

    prefs.overlayEnabled = true
    prefs.overlayLinked = true
    prefs.cameraCaptureMode = .separateCameraAsset
    prefs.excludeRecorderApp = false

    let facade = ScreenRecorderFacade()
    let target = CaptureTarget(mode: .explicitID, displayID: 1)

    let defaultConfig = facade._testBuildCaptureStartConfig(
      target: target,
      effectiveOverlayID: 42
    )
    XCTAssertFalse(defaultConfig.excludeRecorderApp)
    XCTAssertEqual(defaultConfig.cameraOverlayWindowID, 42)
    XCTAssertTrue(defaultConfig.excludeCameraOverlayWindow)

    prefs.excludeRecorderApp = true

    let excludedConfig = facade._testBuildCaptureStartConfig(
      target: target,
      effectiveOverlayID: 42
    )
    XCTAssertTrue(excludedConfig.excludeRecorderApp)
    XCTAssertEqual(excludedConfig.cameraOverlayWindowID, 42)
    XCTAssertTrue(excludedConfig.excludeCameraOverlayWindow)
  }

  func testSeparateCameraModeSuppressesOverlayWindowDuringCaptureOnAVFoundation() {
    let prefs = PreferencesStore()
    let originalOverlayEnabled = prefs.overlayEnabled
    let originalOverlayLinked = prefs.overlayLinked
    let originalCameraCaptureMode = prefs.cameraCaptureMode
    defer {
      prefs.overlayEnabled = originalOverlayEnabled
      prefs.overlayLinked = originalOverlayLinked
      prefs.cameraCaptureMode = originalCameraCaptureMode
    }

    prefs.overlayEnabled = true
    prefs.overlayLinked = true
    prefs.cameraCaptureMode = .separateCameraAsset

    let facade = ScreenRecorderFacade()
    let backend = MockCaptureBackend()
    backend.supportsLiveOverlayExclusionDuringSeparateCameraCapture = false
    facade._testSetCaptureBackend(backend)
    XCTAssertTrue(facade._testShouldSuppressOverlayWindowDuringCapture())
  }

  func testSeparateCameraModeKeepsOverlayVisibleOnScreenCaptureKit() {
    let prefs = PreferencesStore()
    let originalOverlayEnabled = prefs.overlayEnabled
    let originalOverlayLinked = prefs.overlayLinked
    let originalCameraCaptureMode = prefs.cameraCaptureMode
    defer {
      prefs.overlayEnabled = originalOverlayEnabled
      prefs.overlayLinked = originalOverlayLinked
      prefs.cameraCaptureMode = originalCameraCaptureMode
    }

    prefs.overlayEnabled = true
    prefs.overlayLinked = true
    prefs.cameraCaptureMode = .separateCameraAsset

    let facade = ScreenRecorderFacade()
    let backend = MockCaptureBackend()
    backend.supportsLiveOverlayExclusionDuringSeparateCameraCapture = true
    facade._testSetCaptureBackend(backend)
    XCTAssertFalse(facade._testShouldSuppressOverlayWindowDuringCapture())
  }

  func testSeparateCameraOverlaySyncUsesNilOnAVFoundation() {
    let prefs = PreferencesStore()
    let originalOverlayEnabled = prefs.overlayEnabled
    let originalOverlayLinked = prefs.overlayLinked
    let originalCameraCaptureMode = prefs.cameraCaptureMode
    defer {
      prefs.overlayEnabled = originalOverlayEnabled
      prefs.overlayLinked = originalOverlayLinked
      prefs.cameraCaptureMode = originalCameraCaptureMode
    }

    prefs.overlayEnabled = true
    prefs.overlayLinked = true
    prefs.cameraCaptureMode = .separateCameraAsset

    let facade = ScreenRecorderFacade()
    let backend = MockCaptureBackend()
    backend.supportsLiveOverlayExclusionDuringSeparateCameraCapture = false
    facade._testSetCaptureBackend(backend)
    facade._testSetRecorderState(.recording)

    XCTAssertNil(facade._testOverlayWindowIDForCapture(liveOverlayWindowID: 77))
  }

  func testSeparateCameraOverlaySyncUsesLiveOverlayWindowOnScreenCaptureKit() {
    let prefs = PreferencesStore()
    let originalOverlayEnabled = prefs.overlayEnabled
    let originalOverlayLinked = prefs.overlayLinked
    let originalCameraCaptureMode = prefs.cameraCaptureMode
    defer {
      prefs.overlayEnabled = originalOverlayEnabled
      prefs.overlayLinked = originalOverlayLinked
      prefs.cameraCaptureMode = originalCameraCaptureMode
    }

    prefs.overlayEnabled = true
    prefs.overlayLinked = true
    prefs.cameraCaptureMode = .separateCameraAsset

    let facade = ScreenRecorderFacade()
    let backend = MockCaptureBackend()
    backend.supportsLiveOverlayExclusionDuringSeparateCameraCapture = true
    facade._testSetCaptureBackend(backend)
    facade._testSetRecorderState(.recording)

    XCTAssertEqual(facade._testOverlayWindowIDForCapture(liveOverlayWindowID: 77), 77)
  }

  func testCameraRecorderBeginResultDispatchesBeginCaptureToMain() {
    let facade = ScreenRecorderFacade()
    let beginCaptureExpectation = expectation(description: "beginCapture invoked on main")
    let noFailureExpectation = expectation(description: "no failure callback")
    noFailureExpectation.isInverted = true

    DispatchQueue.global(qos: .userInitiated).async {
      Task { @MainActor in
        facade._testHandleCameraRecorderBeginResult(
          .success(()),
          beginCapture: {
            XCTAssertTrue(Thread.isMainThread)
            beginCaptureExpectation.fulfill()
          },
          onFailure: { _ in
            noFailureExpectation.fulfill()
          }
        )
      }
    }

    wait(for: [beginCaptureExpectation, noFailureExpectation], timeout: 1.0)
  }

  func testOverlayUITransitionDispatchesToMain() {
    let facade = ScreenRecorderFacade()
    let expectation = expectation(description: "overlay transition runs on main")

    DispatchQueue.global(qos: .userInitiated).async {
      Task { @MainActor in
        facade._testRunOverlayUITransitionOnMain { isMainThread in
          XCTAssertTrue(isMainThread)
          expectation.fulfill()
        }
      }
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testResolvePreviewMediaSourcesUsesPublishedCameraAsset() throws {
    let tempDir = makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let screenURL = tempDir.appendingPathComponent("recording.mov")
    let cameraURL = AppPaths.cameraRawURL(for: screenURL)
    try Data("screen".utf8).write(to: screenURL)
    try Data("camera".utf8).write(to: cameraURL)

    let metadata = RecordingMetadata.create(
      rawURL: screenURL,
      displayMode: .explicitID,
      displayID: 1,
      cropRect: nil,
      frameRate: 60,
      quality: .fhd,
      cursorEnabled: true,
      cursorLinked: true,
      windowID: nil,
      excludedRecorderApp: false,
      camera: RecordingMetadata.CameraCaptureInfo(
        mode: .separateCameraAsset,
        enabled: true,
        rawRelativePath: cameraURL.lastPathComponent,
        metadataRelativePath: AppPaths.cameraMetadataSidecarURL(for: screenURL).lastPathComponent,
        deviceId: "camera-1",
        mirroredRaw: true,
        nominalFrameRate: 30,
        dimensions: .init(width: 1920, height: 1080),
        segments: []
      ),
      editorSeed: makeEditorSeed()
    )
    try metadata.write(to: AppPaths.metadataSidecarURL(for: screenURL))

    let facade = ScreenRecorderFacade()
    let mediaSources = facade.resolvePreviewMediaSources(source: screenURL.path)

    XCTAssertEqual(mediaSources.cameraPath, cameraURL.path)
  }

  func testResolvePreviewMediaSourcesFallsBackWhenMetadataPointsToMissingInProgressCamera() throws {
    let tempDir = makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let screenURL = tempDir.appendingPathComponent("recording.mov")
    let publishedCameraURL = AppPaths.cameraRawURL(for: screenURL)
    try Data("screen".utf8).write(to: screenURL)
    try Data("camera".utf8).write(to: publishedCameraURL)

    let metadata = RecordingMetadata.create(
      rawURL: screenURL,
      displayMode: .explicitID,
      displayID: 1,
      cropRect: nil,
      frameRate: 60,
      quality: .fhd,
      cursorEnabled: true,
      cursorLinked: true,
      windowID: nil,
      excludedRecorderApp: false,
      camera: RecordingMetadata.CameraCaptureInfo(
        mode: .separateCameraAsset,
        enabled: true,
        rawRelativePath: "recording.123.inprogress.camera.mov",
        metadataRelativePath: "recording.123.inprogress.camera.meta.json",
        deviceId: "camera-1",
        mirroredRaw: true,
        nominalFrameRate: 30,
        dimensions: .init(width: 1920, height: 1080),
        segments: []
      ),
      editorSeed: makeEditorSeed()
    )
    try metadata.write(to: AppPaths.metadataSidecarURL(for: screenURL))

    let facade = ScreenRecorderFacade()
    let mediaSources = facade.resolvePreviewMediaSources(source: screenURL.path)

    XCTAssertNil(mediaSources.cameraPath)
  }

  func testResolvePreviewSceneIncludesTwoSourceMediaAndCameraParams() throws {
    let tempDir = makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let screenURL = tempDir.appendingPathComponent("recording.mov")
    let cameraURL = AppPaths.cameraRawURL(for: screenURL)
    try Data("screen".utf8).write(to: screenURL)
    try Data("camera".utf8).write(to: cameraURL)

    let metadata = RecordingMetadata.create(
      rawURL: screenURL,
      displayMode: .explicitID,
      displayID: 1,
      cropRect: nil,
      frameRate: 60,
      quality: .fhd,
      cursorEnabled: true,
      cursorLinked: true,
      windowID: nil,
      excludedRecorderApp: false,
      camera: RecordingMetadata.CameraCaptureInfo(
        mode: .separateCameraAsset,
        enabled: true,
        rawRelativePath: cameraURL.lastPathComponent,
        metadataRelativePath: AppPaths.cameraMetadataSidecarURL(for: screenURL).lastPathComponent,
        deviceId: "camera-1",
        mirroredRaw: true,
        nominalFrameRate: 30,
        dimensions: .init(width: 1920, height: 1080),
        segments: []
      ),
      editorSeed: makeEditorSeed()
    )
    try metadata.write(to: AppPaths.metadataSidecarURL(for: screenURL))

    let params = CompositionParams(
      targetSize: CGSize(width: 1280, height: 720),
      padding: 0,
      cornerRadius: 0,
      backgroundColor: nil,
      backgroundImagePath: nil,
      cursorSize: 1.0,
      showCursor: true,
      zoomEnabled: true,
      zoomFactor: 1.5,
      followStrength: 0.15,
      fpsHint: 60,
      fitMode: "fit",
      audioGainDb: 0.0,
      audioVolumePercent: 100.0
    )
    let facade = ScreenRecorderFacade()
    let scene = facade.resolvePreviewScene(source: screenURL.path, screenParams: params)

    XCTAssertEqual(scene.mediaSources.screenPath, screenURL.path)
    XCTAssertEqual(scene.mediaSources.cameraPath, cameraURL.path)
    XCTAssertEqual(scene.cameraParams?.layoutPreset, .overlayBottomRight)
  }

  func testRecordingSceneInfoExposesFeatureLevelCameraExportCapabilities() throws {
    let tempDir = makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let screenURL = tempDir.appendingPathComponent("recording.mov")
    let cameraURL = AppPaths.cameraRawURL(for: screenURL)
    try Data("screen".utf8).write(to: screenURL)
    try Data("camera".utf8).write(to: cameraURL)

    let metadata = RecordingMetadata.create(
      rawURL: screenURL,
      displayMode: .explicitID,
      displayID: 1,
      cropRect: nil,
      frameRate: 60,
      quality: .fhd,
      cursorEnabled: true,
      cursorLinked: true,
      windowID: nil,
      excludedRecorderApp: false,
      camera: RecordingMetadata.CameraCaptureInfo(
        mode: .separateCameraAsset,
        enabled: true,
        rawRelativePath: cameraURL.lastPathComponent,
        metadataRelativePath: AppPaths.cameraMetadataSidecarURL(for: screenURL).lastPathComponent,
        deviceId: "camera-1",
        mirroredRaw: true,
        nominalFrameRate: 30,
        dimensions: .init(width: 1920, height: 1080),
        segments: []
      ),
      editorSeed: makeEditorSeed()
    )
    try metadata.write(to: AppPaths.metadataSidecarURL(for: screenURL))

    let facade = ScreenRecorderFacade()
    var scenePayload: Any?
    facade.getRecordingSceneInfo(source: screenURL.path) { value in
      scenePayload = value
    }

    let payload = try XCTUnwrap(scenePayload as? [String: Any])
    XCTAssertEqual(payload["cameraPath"] as? String, cameraURL.path)
    XCTAssertEqual(payload["supportsAdvancedCameraExportStyling"] as? Bool, false)
    let capabilities = try XCTUnwrap(payload["cameraExportCapabilities"] as? [String: Bool])
    XCTAssertEqual(capabilities["shapeMask"], true)
    XCTAssertEqual(capabilities["cornerRadius"], true)
    XCTAssertEqual(capabilities["border"], true)
    XCTAssertEqual(capabilities["shadow"], true)
    XCTAssertEqual(capabilities["chromaKey"], false)
  }

  func testSeparateCameraExportSanitizesOnlyUnsupportedChromaKeyStyling() {
    let params = CameraCompositionParams(
      visible: true,
      layoutPreset: .overlayBottomRight,
      normalizedCanvasCenter: CGPoint(x: 0.5, y: 0.5),
      sizeFactor: 0.2,
      shape: .circle,
      cornerRadius: 0.35,
      opacity: 0.9,
      mirror: true,
      contentMode: .fill,
      zoomBehavior: .fixed,
      borderWidth: 6,
      borderColorArgb: 0xFFFFFFFF,
      shadowPreset: 2,
      chromaKeyEnabled: true,
      chromaKeyStrength: 0.8,
      chromaKeyColorArgb: 0xFF00FF00
    )

    let facade = ScreenRecorderFacade()
    let sanitized = facade._testSanitizedCameraParamsForExport(
      params,
      cameraPath: "/tmp/recording.camera.mov"
    )

    XCTAssertEqual(sanitized?.shape, params.shape)
    XCTAssertEqual(sanitized?.cornerRadius, params.cornerRadius)
    XCTAssertEqual(sanitized?.borderWidth, params.borderWidth)
    XCTAssertEqual(sanitized?.borderColorArgb, params.borderColorArgb)
    XCTAssertEqual(sanitized?.shadowPreset, params.shadowPreset)
    XCTAssertEqual(sanitized?.chromaKeyEnabled, false)
    XCTAssertNil(sanitized?.chromaKeyColorArgb)
    XCTAssertEqual(sanitized?.chromaKeyStrength, 0.4)
    XCTAssertEqual(sanitized?.opacity, params.opacity)
    XCTAssertEqual(sanitized?.mirror, params.mirror)
  }

  func testSeparateCameraRecorderFailureStopsCaptureAndStoresFailure() {
    let prefs = PreferencesStore()
    let originalOverlayEnabled = prefs.overlayEnabled
    let originalOverlayLinked = prefs.overlayLinked
    let originalCameraCaptureMode = prefs.cameraCaptureMode
    defer {
      prefs.overlayEnabled = originalOverlayEnabled
      prefs.overlayLinked = originalOverlayLinked
      prefs.cameraCaptureMode = originalCameraCaptureMode
    }

    prefs.overlayEnabled = true
    prefs.overlayLinked = true
    prefs.cameraCaptureMode = .separateCameraAsset

    let facade = ScreenRecorderFacade()
    let backend = MockCaptureBackend()
    backend.supportsLiveOverlayExclusionDuringSeparateCameraCapture = true
    facade._testSetCaptureBackend(backend)
    facade._testSetRecorderState(.recording)

    facade._testHandleSeparateCameraRecorderFailure(
      FlutterError(code: NativeErrorCode.recordingError, message: "camera failed", details: nil)
    )

    XCTAssertEqual(backend.stopCallCount, 1)
    XCTAssertEqual(facade._testPendingSeparateCameraFailureCode(), NativeErrorCode.recordingError)
    XCTAssertEqual(
      (facade._testTerminalRecordingError(screenError: nil) as? FlutterError)?.message,
      "camera failed"
    )
  }

  private func makeTemporaryDirectory() -> URL {
    let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try? FileManager.default.createDirectory(
      at: url,
      withIntermediateDirectories: true,
      attributes: nil
    )
    return url
  }

  private func makeEditorSeed() -> RecordingMetadata.EditorSeed {
    RecordingMetadata.EditorSeed(
      cameraVisible: true,
      cameraLayoutPreset: .overlayBottomRight,
      cameraNormalizedCenter: nil,
      cameraSizeFactor: 0.18,
      cameraShape: .circle,
      cameraCornerRadius: 0.0,
      cameraBorderWidth: 0.0,
      cameraBorderColorArgb: nil,
      cameraShadow: 0,
      cameraOpacity: 1.0,
      cameraMirror: true,
      cameraContentMode: .fill,
      cameraZoomBehavior: .fixed,
      cameraChromaKeyEnabled: false,
      cameraChromaKeyStrength: 0.4,
      cameraChromaKeyColorArgb: nil
    )
  }
}
