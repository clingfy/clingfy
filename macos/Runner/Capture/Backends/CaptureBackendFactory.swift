//
//  CaptureBackendFactory.swift
//  Runner
//
//  Created by Nabil Alhafez on 31/12/2025.
//

import Foundation

enum CaptureBackendFactory {

  // FIX: Mark this method as @MainActor so it can call the @MainActor-isolated
  // initializer of CaptureBackendScreenCaptureKit.
  @MainActor
  static func make(for target: CaptureTarget) -> CaptureBackend {
    if #available(macOS 15.0, *) {
      NativeLogger.i(
        "CaptureFactory", "Using ScreenCaptureKit backend",
        context: [
          "mode": "\(target.mode)",
          "displayID": Int(target.displayID),
          "windowID": Int(target.windowID ?? 0),
        ])
      return CaptureBackendScreenCaptureKit()
    }

    NativeLogger.i(
      "CaptureFactory", "Using AVFoundation backend \(target.mode)",
      context: [
        "mode": "\(target.mode)",
        "displayID": Int(target.displayID),
      ])
    return CaptureBackendAVFoundation()
  }
}
