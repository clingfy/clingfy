//
//  PermissionsMethodRouter.swift
//  Runner
//
//  Created by Nabil Alhafez on 07/02/2026.
//

import FlutterMacOS
import Foundation

final class PermissionsMethodRouter {
  private let facade: ScreenRecorderFacade
  init(facade: ScreenRecorderFacade) { self.facade = facade }

  func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) -> Bool {
    switch call.method {

    case "getPermissionStatus":
      Task { @MainActor in
        facade.getPermissionStatus(result: result)
      }
      return true

    case "requestScreenRecordingPermission":
      Task { @MainActor in
        facade.requestScreenRecordingPermission(result: result)
      }
      return true

    case "requestMicrophonePermission":
      Task { @MainActor in
        facade.requestMicrophonePermission(result: result)
      }
      return true

    case "requestCameraPermission":
      Task { @MainActor in
        facade.requestCameraPermission(result: result)
      }
      return true

    case "openAccessibilitySettings":
      Task { @MainActor in
        let ok = facade.ensureAccessibilityAllowedAndGuideUser()
        result(NSNumber(value: ok))
      }
      return true

    case "openScreenRecordingSettings":
      Task { @MainActor in
        facade.openScreenRecordingSettings()
        result(nil)
      }
      return true

    case "relaunchApp":
      Task { @MainActor in
        facade.relaunchApp()
        result(nil)
      }
      return true

    default:
      return false
    }
  }
}
