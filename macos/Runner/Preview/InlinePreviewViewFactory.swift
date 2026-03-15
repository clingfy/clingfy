//
//  InlinePreviewViewFactory.swift
//  Runner
//
//  Created by Nabil Alhafez on 13/11/2025.
//
import AVFoundation
import Cocoa
import FlutterMacOS
import Foundation

var inlinePreviewViewInstance: InlinePreviewView?
var inlinePreviewPlayerEventSink: FlutterEventSink?
var workflowLifecycleEventSink: FlutterEventSink?
var pendingPreviewParams: CompositionParams?
var pendingPreviewZoomSegments: [ZoomTimelineSegment]?

struct PendingPreviewOpenRequest {
  let sessionId: String
  let path: String
}

var pendingPreviewOpenRequest: PendingPreviewOpenRequest?

final class InlinePreviewViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  // macOS: return NSView, not FlutterPlatformView

  func create(
    withViewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> NSView {
    NativeLogger.i(
      "Preview", "Creating inline preview host view",
      context: [
        "viewId": "\(viewId)",
        "hasPendingOpenRequest": pendingPreviewOpenRequest != nil,
        "hasPendingPreviewParams": pendingPreviewParams != nil,
        "hasPendingZoomSegments": pendingPreviewZoomSegments != nil,
      ])
    let v = InlinePreviewView(
      viewIdentifier: viewId,
      arguments: args,
      messenger: messenger
    )
    inlinePreviewViewInstance = v
    v.playerEventSink = inlinePreviewPlayerEventSink
    v.workflowEventSink = workflowLifecycleEventSink

    if let params = pendingPreviewParams {
      NativeLogger.i("Preview", "Applying pending preview params to new host view")
      v.updateComposition(params: params)
      pendingPreviewParams = nil
    }

    if let request = pendingPreviewOpenRequest {
      NativeLogger.i(
        "Preview", "Consuming pending previewOpen request in new host view",
        context: [
          "sessionId": request.sessionId,
          "path": request.path,
        ])
      v.open(path: request.path, sessionId: request.sessionId)
      pendingPreviewOpenRequest = nil
    }

    if let segments = pendingPreviewZoomSegments {
      NativeLogger.i(
        "Preview", "Applying pending zoom segments to new host view",
        context: ["count": "\(segments.count)"])
      v.updateZoomSegmentsOnly(segments: segments)
      pendingPreviewZoomSegments = nil
    }

    return v
  }

  func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}
