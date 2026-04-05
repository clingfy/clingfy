import Foundation

enum ProjectOpenValidator {
  static func validateProjectURL(
    _ url: URL,
    fileManager: FileManager = .default
  ) throws -> RecordingProjectRef {
    let standardizedURL = url.standardizedFileURL
    guard standardizedURL.isFileURL else {
      throw RecordingProjectManifestError.invalidProjectDirectory(standardizedURL.path)
    }

    var isDirectory: ObjCBool = false
    guard
      fileManager.fileExists(atPath: standardizedURL.path, isDirectory: &isDirectory),
      isDirectory.boolValue,
      RecordingProjectPaths.isProjectDirectory(standardizedURL)
    else {
      throw RecordingProjectManifestError.invalidProjectDirectory(standardizedURL.path)
    }

    return try validateProjectRoot(standardizedURL, fileManager: fileManager)
  }

  static func validateProjectPath(
    _ projectPath: String,
    fileManager: FileManager = .default
  ) throws -> RecordingProjectRef {
    try validateProjectRoot(URL(fileURLWithPath: projectPath), fileManager: fileManager)
  }

  static func validateProjectRoot(
    _ projectRoot: URL,
    fileManager: FileManager = .default
  ) throws -> RecordingProjectRef {
    let projectRef = try RecordingProjectRef.open(projectRoot: projectRoot)
    let missingFiles = missingRequiredReadyProjectFiles(
      for: projectRef.manifest,
      projectRootURL: projectRef.rootURL,
      fileManager: fileManager
    )

    if projectRef.manifest.status == .ready && !missingFiles.isEmpty {
      throw RecordingProjectManifestError.missingRequiredProjectFiles(
        missingFiles.map(\.path)
      )
    }

    return projectRef
  }

  static func missingRequiredReadyProjectFiles(
    for manifest: RecordingProjectManifest,
    projectRootURL: URL,
    fileManager: FileManager = .default
  ) -> [URL] {
    let screenVideoURL =
      RecordingProjectPaths.resolvedURL(
        for: manifest.capture.screenVideo,
        projectRoot: projectRootURL
      ) ?? RecordingProjectPaths.screenVideoURL(for: projectRootURL)
    let metadataURL =
      RecordingProjectPaths.resolvedURL(
        for: manifest.capture.screenMetadata,
        projectRoot: projectRootURL
      ) ?? RecordingProjectPaths.screenMetadataURL(for: projectRootURL)

    var requiredFiles = [screenVideoURL, metadataURL]

    if let camera = manifest.camera {
      let cameraRawURL =
        RecordingProjectPaths.resolvedURL(for: camera.rawVideo, projectRoot: projectRootURL)
        ?? RecordingProjectPaths.cameraRawURL(for: projectRootURL)
      requiredFiles.append(cameraRawURL)
    }

    return requiredFiles.filter { !fileManager.fileExists(atPath: $0.path) }
  }
}
