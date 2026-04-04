import Foundation
import XCTest

@testable import Clingfy

final class RecordingFailureRecoveryTests: XCTestCase {
  func testCaptureDestinationUsesProjectScreenURLWhenProjectIsActive() {
    let projectRoot = URL(fileURLWithPath: "/tmp/demo.clingfy", isDirectory: true)

    XCTAssertEqual(
      CaptureDestinationDiagnostics.url(for: projectRoot).standardizedFileURL,
      RecordingProjectPaths.screenVideoURL(for: projectRoot).standardizedFileURL
    )
  }

  func testCaptureDestinationFallsBackToTempRootWhenIdle() {
    XCTAssertEqual(
      CaptureDestinationDiagnostics.url(for: nil).standardizedFileURL,
      AppPaths.tempRoot().standardizedFileURL
    )
  }

  func testRecordingStoreMarksInterruptedProjectsAsFailed() throws {
    let rootURL = makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootURL) }

    let fileManager = FileManager.default
    let interruptedRoot = rootURL.appendingPathComponent("rec_interrupted.clingfy", isDirectory: true)
    let readyRoot = rootURL.appendingPathComponent("rec_ready.clingfy", isDirectory: true)

    try createProjectSkeleton(at: interruptedRoot, projectId: "rec_interrupted")
    try createProjectSkeleton(at: readyRoot, projectId: "rec_ready")

    var interrupted = try RecordingProjectManifest.read(
      from: RecordingProjectPaths.manifestURL(for: interruptedRoot)
    )
    interrupted.updateStatus(.capturing)
    try interrupted.write(to: RecordingProjectPaths.manifestURL(for: interruptedRoot))

    var ready = try RecordingProjectManifest.read(
      from: RecordingProjectPaths.manifestURL(for: readyRoot)
    )
    ready.updateStatus(.ready)
    try ready.write(to: RecordingProjectPaths.manifestURL(for: readyRoot))

    let store = RecordingStore(rootURL: rootURL, fileManager: fileManager)
    store.markInterruptedProjectsAsFailed()

    let updatedInterrupted = try RecordingProjectManifest.read(
      from: RecordingProjectPaths.manifestURL(for: interruptedRoot)
    )
    let updatedReady = try RecordingProjectManifest.read(
      from: RecordingProjectPaths.manifestURL(for: readyRoot)
    )

    XCTAssertEqual(updatedInterrupted.status, .failed)
    XCTAssertEqual(updatedReady.status, .ready)
  }

  func testLegacyWorkspaceResetWipesFlatArtifactsAndCreatesSentinel() throws {
    let rootURL = makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootURL) }

    let fileManager = FileManager.default
    let legacyVideo = rootURL.appendingPathComponent("legacy.mov")
    let legacyMetadata = rootURL.appendingPathComponent("legacy.meta.json")
    try Data("video".utf8).write(to: legacyVideo)
    try Data("metadata".utf8).write(to: legacyMetadata)

    let didReset = RecordingProjectPaths.performOneTimeLegacyWorkspaceResetIfNeeded(
      isNonProductionBuild: true,
      rootURL: rootURL,
      fileManager: fileManager
    )

    XCTAssertTrue(didReset)
    XCTAssertFalse(fileManager.fileExists(atPath: legacyVideo.path))
    XCTAssertFalse(fileManager.fileExists(atPath: legacyMetadata.path))
    XCTAssertTrue(
      fileManager.fileExists(
        atPath: RecordingProjectPaths.schemaSentinelURL(rootURL: rootURL).path
      )
    )
  }

  func testLegacyWorkspaceResetOnlyRunsOnceWhenSentinelExists() throws {
    let rootURL = makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootURL) }

    let fileManager = FileManager.default
    try RecordingProjectPaths.ensureSchemaSentinel(rootURL: rootURL, fileManager: fileManager)
    let legacyVideo = rootURL.appendingPathComponent("legacy.mov")
    try Data("video".utf8).write(to: legacyVideo)

    let didReset = RecordingProjectPaths.performOneTimeLegacyWorkspaceResetIfNeeded(
      isNonProductionBuild: true,
      rootURL: rootURL,
      fileManager: fileManager
    )

    XCTAssertFalse(didReset)
    XCTAssertTrue(fileManager.fileExists(atPath: legacyVideo.path))
  }

  func testTerminalCompletionGuardSuppressesDuplicatesUntilReset() {
    var guardState = TerminalCompletionGuard()

    XCTAssertTrue(guardState.beginCompletion())
    XCTAssertFalse(guardState.beginCompletion())

    guardState.reset()

    XCTAssertTrue(guardState.beginCompletion())
  }

  func testCursorFailurePlanFlushesWhenCursorCaptureIsActiveAndURLExists() {
    let recordingURL = URL(fileURLWithPath: "/tmp/recording.inprogress.mov")

    let plan = CursorFailureFinalizationPlan.make(
      recordingURL: recordingURL,
      cursorCaptureActive: true
    )

    XCTAssertTrue(plan.shouldFlushCursor)
    XCTAssertEqual(
      plan.cursorURL,
      recordingURL.deletingPathExtension().appendingPathExtension("cursor.json")
    )
  }

  func testCursorFailurePlanSkipsFlushWithoutURLOrInactiveCursorCapture() {
    let inactivePlan = CursorFailureFinalizationPlan.make(
      recordingURL: URL(fileURLWithPath: "/tmp/recording.inprogress.mov"),
      cursorCaptureActive: false
    )
    let nilURLPlan = CursorFailureFinalizationPlan.make(
      recordingURL: nil,
      cursorCaptureActive: true
    )

    XCTAssertFalse(inactivePlan.shouldFlushCursor)
    XCTAssertFalse(nilURLPlan.shouldFlushCursor)
    XCTAssertNil(nilURLPlan.cursorURL)
  }

  func testCursorRecorderStopWithoutStartDoesNotCreateSidecar() {
    let recorder = CursorRecorder()
    let outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("cursor.json")
    let completion = expectation(description: "cursor stop completion")

    recorder.stop(outputURL: outputURL) {
      completion.fulfill()
    }

    wait(for: [completion], timeout: 1.0)
    XCTAssertFalse(FileManager.default.fileExists(atPath: outputURL.path))
  }

  func testCursorRecordingWriterCompletesAfterSidecarExists() {
    let outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("cursor.json")
    let recording = CursorRecording(
      sprites: [],
      frames: [CursorFrame(t: 0.0, x: 0.5, y: 0.25, spriteID: -1)]
    )
    let completion = expectation(description: "cursor writer completion")

    CursorRecordingWriter.write(
      recording: recording,
      to: outputURL,
      queue: DispatchQueue(label: "test.cursor.writer")
    ) {
      XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

      do {
        let data = try Data(contentsOf: outputURL)
        let decoded = try JSONDecoder().decode(CursorRecording.self, from: data)
        XCTAssertEqual(decoded.frames.count, 1)
      } catch {
        XCTFail("Expected cursor sidecar to be readable before completion: \(error)")
      }

      try? FileManager.default.removeItem(at: outputURL)
      completion.fulfill()
    }

    wait(for: [completion], timeout: 1.0)
  }

  func testStorageInfoProviderSnapshotCarriesThresholdsAndPaths() {
    let snapshot = StorageInfoProvider.buildSnapshot(
      captureDestinationURL: AppPaths.tempRoot(),
      recordingsURL: AppPaths.recordingsRoot(),
      tempURL: AppPaths.tempRoot(),
      logsURL: AppPaths.logsRoot()
    )

    XCTAssertEqual(snapshot.warningThresholdBytes, StorageInfoProvider.warningThresholdBytes)
    XCTAssertEqual(snapshot.criticalThresholdBytes, StorageInfoProvider.criticalThresholdBytes)
    XCTAssertEqual(snapshot.recordingsPath, AppPaths.recordingsRoot().path)
    XCTAssertEqual(snapshot.tempPath, AppPaths.tempRoot().path)
    XCTAssertEqual(snapshot.logsPath, AppPaths.logsRoot().path)
  }

  func testStorageInfoProviderDirectorySizeReturnsZeroForMissingDirectory() {
    let missingURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString, isDirectory: true)

    XCTAssertEqual(StorageInfoProvider.directorySize(missingURL), 0)
  }

  func testStorageInfoProviderBuildSnapshotAggregatesRecordingTempAndLogs() throws {
    let rootURL = makeTemporaryDirectory()
    let recordingsURL = rootURL.appendingPathComponent("recordings", isDirectory: true)
    let tempURL = rootURL.appendingPathComponent("temp", isDirectory: true)
    let logsURL = rootURL.appendingPathComponent("logs", isDirectory: true)
    let fileManager = FileManager.default

    try fileManager.createDirectory(at: recordingsURL, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: tempURL, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: logsURL, withIntermediateDirectories: true)
    defer { try? fileManager.removeItem(at: rootURL) }

    let recordingsData = Data("recordings".utf8)
    let tempData = Data("temp".utf8)
    let logsData = Data("logs".utf8)

    try recordingsData.write(to: recordingsURL.appendingPathComponent("a.mov"))
    try tempData.write(to: tempURL.appendingPathComponent("b.mov"))
    try logsData.write(to: logsURL.appendingPathComponent("c.jsonl"))

    let snapshot = StorageInfoProvider.buildSnapshot(
      captureDestinationURL: tempURL,
      recordingsURL: recordingsURL,
      tempURL: tempURL,
      logsURL: logsURL
    )

    XCTAssertGreaterThan(snapshot.systemTotalBytes, 0)
    XCTAssertGreaterThan(snapshot.systemAvailableBytes, 0)
    XCTAssertGreaterThanOrEqual(snapshot.recordingsBytes, Int64(recordingsData.count))
    XCTAssertGreaterThanOrEqual(snapshot.tempBytes, Int64(tempData.count))
    XCTAssertGreaterThanOrEqual(snapshot.logsBytes, Int64(logsData.count))
  }

  func testRecordingStoreDeleteAllOnlyRemovesProjectsFromRecordingsWorkspace() throws {
    let rootURL = makeTemporaryDirectory()
    let recordingsURL = rootURL.appendingPathComponent("recordings", isDirectory: true)
    let tempURL = rootURL.appendingPathComponent("temp", isDirectory: true)
    let logsURL = rootURL.appendingPathComponent("logs", isDirectory: true)
    let fileManager = FileManager.default

    try fileManager.createDirectory(at: recordingsURL, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: tempURL, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: logsURL, withIntermediateDirectories: true)
    defer { try? fileManager.removeItem(at: rootURL) }

    let projectRoot = recordingsURL.appendingPathComponent("clip.clingfy", isDirectory: true)
    try createProjectSkeleton(at: projectRoot, projectId: "clip")
    let tempArtifactURL = tempURL.appendingPathComponent("capture.inprogress.mov")
    let logURL = logsURL.appendingPathComponent("logs_2026-03-25.jsonl")

    try Data("temp".utf8).write(to: tempArtifactURL)
    try Data("log".utf8).write(to: logURL)

    let store = RecordingStore(rootURL: recordingsURL, fileManager: fileManager)
    let deletedCount = store.deleteAll()

    XCTAssertEqual(deletedCount, 1)
    XCTAssertFalse(fileManager.fileExists(atPath: projectRoot.path))
    XCTAssertTrue(fileManager.fileExists(atPath: tempArtifactURL.path))
    XCTAssertTrue(fileManager.fileExists(atPath: logURL.path))
  }

  func testCachedRecordingsCleanupPolicyAllowsOnlyIdleState() {
    XCTAssertTrue(CachedRecordingsCleanupPolicy.canClear(recorderState: .idle))
    XCTAssertFalse(CachedRecordingsCleanupPolicy.canClear(recorderState: .starting))
    XCTAssertFalse(CachedRecordingsCleanupPolicy.canClear(recorderState: .recording))
    XCTAssertFalse(CachedRecordingsCleanupPolicy.canClear(recorderState: .stopping))
  }

  func testCaptureDestinationPreflightBypassAllowedForNonProductionBuilds() {
    XCTAssertTrue(
      CaptureDestinationPreflightPolicy.shouldBypassLowStorageCheck(
        requested: true,
        bundleIdentifier: "com.clingfy.clingfy.dev",
        isDebugBuild: false
      )
    )

    XCTAssertEqual(
      CaptureDestinationPreflightPolicy.decision(
        availableBytes: 0,
        requestedBypass: true,
        bundleIdentifier: "com.clingfy.clingfy.dev",
        isDebugBuild: false
      ),
      .proceed
    )
  }

  func testCaptureDestinationPreflightBypassIgnoredInProductionBuilds() {
    XCTAssertFalse(
      CaptureDestinationPreflightPolicy.shouldBypassLowStorageCheck(
        requested: true,
        bundleIdentifier: "com.clingfy.clingfy",
        isDebugBuild: false
      )
    )

    XCTAssertEqual(
      CaptureDestinationPreflightPolicy.decision(
        availableBytes: 5 * 1024 * 1024 * 1024,
        requestedBypass: true,
        bundleIdentifier: "com.clingfy.clingfy",
        isDebugBuild: false
      ),
      .belowCriticalThreshold
    )
  }

  private func makeTemporaryDirectory() -> URL {
    let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }

  private func createProjectSkeleton(at projectRoot: URL, projectId: String) throws {
    let fileManager = FileManager.default
    try fileManager.createDirectory(at: projectRoot, withIntermediateDirectories: true)
    try fileManager.createDirectory(
      at: RecordingProjectPaths.captureDirectoryURL(for: projectRoot),
      withIntermediateDirectories: true
    )
    try fileManager.createDirectory(
      at: RecordingProjectPaths.cameraSegmentsDirectoryURL(for: projectRoot),
      withIntermediateDirectories: true
    )
    try fileManager.createDirectory(
      at: RecordingProjectPaths.postDirectoryURL(for: projectRoot),
      withIntermediateDirectories: true
    )
    try fileManager.createDirectory(
      at: RecordingProjectPaths.derivedDirectoryURL(for: projectRoot),
      withIntermediateDirectories: true
    )

    let manifest = RecordingProjectManifest.create(
      projectId: projectId,
      displayName: "Clingfy Test",
      includeCamera: false
    )
    try manifest.write(to: RecordingProjectPaths.manifestURL(for: projectRoot))
  }
}
