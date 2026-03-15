import Cocoa

// Compatibility wrapper while routing selection through the coordinator.
enum AreaSelectionOverlay {
  static func show(
    onDisplay displayID: CGDirectDisplayID,
    completion: @escaping ((displayID: CGDirectDisplayID, rect: CGRect)?) -> Void
  ) {
    AreaSelectionCoordinator.show(initialDisplayID: displayID, completion: completion)
  }
}

private protocol AreaSelectionSurfaceViewDelegate: AnyObject {
  func selectionDidBegin(on displayID: CGDirectDisplayID, at pointInWindow: NSPoint)
  func selectionDidChange(on displayID: CGDirectDisplayID, to pointInWindow: NSPoint)
  func selectionDidEnd(on displayID: CGDirectDisplayID, at pointInWindow: NSPoint)
  func selectionDidCancel()
}

final class AreaSelectionCoordinator: NSObject {
  private static var activeCoordinator: AreaSelectionCoordinator?

  private var windows: [CGDirectDisplayID: NSWindow] = [:]
  private var views: [CGDirectDisplayID: AreaSelectionSurfaceView] = [:]

  private var activeDisplayID: CGDirectDisplayID?
  private var startScreenPoint: NSPoint?
  private var currentScreenPoint: NSPoint?

  private var completion: (((displayID: CGDirectDisplayID, rect: CGRect)?) -> Void)?
  private var didFinish = false

  static func show(
    initialDisplayID: CGDirectDisplayID?,
    completion: @escaping ((displayID: CGDirectDisplayID, rect: CGRect)?) -> Void
  ) {
    // End any stale/active session before starting another.
    if let existing = activeCoordinator {
      existing.finish(with: nil)
    }

    let coordinator = AreaSelectionCoordinator()
    coordinator.completion = completion
    activeCoordinator = coordinator
    coordinator.present(initialDisplayID: initialDisplayID)
  }

  private func present(initialDisplayID: CGDirectDisplayID?) {
    for screen in NSScreen.screens {
      guard
        let displayID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
          as? NSNumber)?.uint32Value
      else {
        continue
      }

      let window = NSWindow(
        contentRect: screen.frame,
        styleMask: [.borderless],
        backing: .buffered,
        defer: false
      )
      window.isOpaque = false
      window.backgroundColor = .clear
      window.level = .screenSaver
      window.hasShadow = false
      window.ignoresMouseEvents = false
      window.acceptsMouseMovedEvents = true
      window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

      let view = AreaSelectionSurfaceView(frame: window.contentView!.bounds, displayID: displayID)
      view.autoresizingMask = [.width, .height]
      view.delegate = self

      window.contentView = view
      windows[displayID] = window
      views[displayID] = view
      window.makeKeyAndOrderFront(nil)
    }

    NSApp.activate(ignoringOtherApps: true)

    if let preferred = initialDisplayID,
      let preferredWindow = windows[preferred],
      let preferredView = views[preferred]
    {
      preferredWindow.makeKey()
      preferredWindow.makeFirstResponder(preferredView)
    } else if let firstWindow = windows.values.first,
      let firstDisplayID = windows.first(where: { $0.value === firstWindow })?.key,
      let firstView = views[firstDisplayID]
    {
      firstWindow.makeKey()
      firstWindow.makeFirstResponder(firstView)
    }
  }

  private func clampToDisplay(_ point: NSPoint, displayID: CGDirectDisplayID) -> NSPoint {
    guard let frame = windows[displayID]?.screen?.frame else { return point }

    let clampedX = min(max(point.x, frame.minX), frame.maxX)
    let clampedY = min(max(point.y, frame.minY), frame.maxY)
    return NSPoint(x: clampedX, y: clampedY)
  }

  private func normalizeToDisplay(_ screenRect: CGRect, displayID: CGDirectDisplayID) -> CGRect {
    guard let screenFrame = windows[displayID]?.screen?.frame else { return screenRect }
    return CGRect(
      x: screenRect.origin.x - screenFrame.origin.x,
      y: screenFrame.height - (screenRect.origin.y - screenFrame.origin.y) - screenRect.size.height,
      width: screenRect.size.width,
      height: screenRect.size.height
    )
  }

  private func refreshViews() {
    for (displayID, view) in views {
      view.updateSelection(
        activeDisplayID: activeDisplayID,
        startScreenPoint: startScreenPoint,
        currentScreenPoint: currentScreenPoint
      )

      // Keep crosshair cursor consistent on all selection surfaces.
      if let window = windows[displayID] {
        window.invalidateCursorRects(for: view)
      }
    }
  }

  private func finish(with result: (displayID: CGDirectDisplayID, rect: CGRect)?) {
    guard !didFinish else { return }
    didFinish = true

    windows.values.forEach { $0.orderOut(nil) }
    windows.removeAll()
    views.removeAll()

    completion?(result)
    completion = nil

    if AreaSelectionCoordinator.activeCoordinator === self {
      AreaSelectionCoordinator.activeCoordinator = nil
    }
  }
}

extension AreaSelectionCoordinator: AreaSelectionSurfaceViewDelegate {
  func selectionDidBegin(on displayID: CGDirectDisplayID, at pointInWindow: NSPoint) {
    guard let window = windows[displayID] else { return }

    activeDisplayID = displayID
    let screenPoint = window.convertPoint(toScreen: pointInWindow)
    let clampedPoint = clampToDisplay(screenPoint, displayID: displayID)
    startScreenPoint = clampedPoint
    currentScreenPoint = clampedPoint
    refreshViews()
  }

  func selectionDidChange(on displayID: CGDirectDisplayID, to pointInWindow: NSPoint) {
    guard let activeDisplayID, displayID == activeDisplayID,
      let window = windows[activeDisplayID]
    else {
      return
    }

    let screenPoint = window.convertPoint(toScreen: pointInWindow)
    currentScreenPoint = clampToDisplay(screenPoint, displayID: activeDisplayID)
    refreshViews()
  }

  func selectionDidEnd(on displayID: CGDirectDisplayID, at pointInWindow: NSPoint) {
    guard let activeDisplayID, displayID == activeDisplayID,
      let window = windows[activeDisplayID],
      let start = startScreenPoint
    else {
      finish(with: nil)
      return
    }

    let end = clampToDisplay(window.convertPoint(toScreen: pointInWindow), displayID: activeDisplayID)

    let screenRect = CGRect(
      x: min(start.x, end.x),
      y: min(start.y, end.y),
      width: abs(start.x - end.x),
      height: abs(start.y - end.y)
    )

    guard screenRect.width > 5, screenRect.height > 5 else {
      finish(with: nil)
      return
    }

    let localRect = normalizeToDisplay(screenRect, displayID: activeDisplayID)
    finish(with: (displayID: activeDisplayID, rect: localRect))
  }

  func selectionDidCancel() {
    finish(with: nil)
  }
}

private final class AreaSelectionSurfaceView: NSView {
  weak var delegate: AreaSelectionSurfaceViewDelegate?

  private let displayID: CGDirectDisplayID
  private var isActiveDisplay = false
  private var selectionRect: NSRect?

  init(frame frameRect: NSRect, displayID: CGDirectDisplayID) {
    self.displayID = displayID
    super.init(frame: frameRect)
  }

  required init?(coder: NSCoder) {
    return nil
  }

  override var acceptsFirstResponder: Bool { true }

  override func resetCursorRects() {
    super.resetCursorRects()
    addCursorRect(bounds, cursor: .crosshair)
  }

  override func cursorUpdate(with event: NSEvent) {
    NSCursor.crosshair.set()
  }

  override func mouseDown(with event: NSEvent) {
    NSCursor.crosshair.set()
    delegate?.selectionDidBegin(on: displayID, at: convert(event.locationInWindow, from: nil))
  }

  override func mouseDragged(with event: NSEvent) {
    NSCursor.crosshair.set()
    delegate?.selectionDidChange(on: displayID, to: convert(event.locationInWindow, from: nil))
  }

  override func mouseUp(with event: NSEvent) {
    NSCursor.arrow.set()
    delegate?.selectionDidEnd(on: displayID, at: convert(event.locationInWindow, from: nil))
  }

  override func keyDown(with event: NSEvent) {
    if event.keyCode == 53 {  // Escape
      delegate?.selectionDidCancel()
      return
    }
    super.keyDown(with: event)
  }

  func updateSelection(
    activeDisplayID: CGDirectDisplayID?,
    startScreenPoint: NSPoint?,
    currentScreenPoint: NSPoint?
  ) {
    let isActive = (activeDisplayID == displayID)
    isActiveDisplay = isActive

    if isActive,
      let startScreenPoint,
      let currentScreenPoint,
      let window
    {
      let localStart = window.convertPoint(fromScreen: startScreenPoint)
      let localCurrent = window.convertPoint(fromScreen: currentScreenPoint)

      let rect = NSRect(
        x: min(localStart.x, localCurrent.x),
        y: min(localStart.y, localCurrent.y),
        width: abs(localStart.x - localCurrent.x),
        height: abs(localStart.y - localCurrent.y)
      )
      let clipped = rect.intersection(bounds)
      selectionRect = clipped.isNull ? nil : clipped
    } else {
      selectionRect = nil
    }

    needsDisplay = true
  }

  override func draw(_ dirtyRect: NSRect) {
    NSColor(white: 0, alpha: 0.45).setFill()
    dirtyRect.fill()

    guard isActiveDisplay, let selectionRect else { return }

    NSColor.clear.setFill()
    selectionRect.fill(using: .copy)

    let border = NSBezierPath(rect: selectionRect)
    border.lineWidth = 2
    NSColor.white.setStroke()
    border.stroke()
  }
}

class AreaPreviewOverlay: NSWindowController {
  private static var instance: AreaPreviewOverlay?
  private static var hideToken: UUID?

  private var previewWindow: NSWindow?
  private var previewView: AreaPreviewView?
  private var currentDisplayID: CGDirectDisplayID?
  private var currentRect: CGRect?

  static func show(displayID: CGDirectDisplayID, rect: CGRect, autoHideAfter: TimeInterval = 1.0) {
    if instance == nil {
      instance = AreaPreviewOverlay()
    }
    instance?.update(displayID: displayID, rect: rect)

    guard autoHideAfter > 0 else { return }
    let token = UUID()
    hideToken = token
    DispatchQueue.main.asyncAfter(deadline: .now() + autoHideAfter) {
      guard hideToken == token else { return }
      hide()
    }
  }

  static func hide() {
    hideToken = nil
    instance?.close()
    instance = nil
  }

  init() {
    super.init(window: nil)
  }

  required init?(coder: NSCoder) {
    return nil
  }

  func update(displayID: CGDirectDisplayID, rect: CGRect) {
    let screen =
      NSScreen.screens.first {
        ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
          == displayID
      } ?? NSScreen.main!

    if previewWindow == nil {
      let window = NSWindow(
        contentRect: screen.frame,
        styleMask: [.borderless],
        backing: .buffered,
        defer: false
      )
      window.isOpaque = false
      window.backgroundColor = .clear
      window.level = .screenSaver
      window.hasShadow = false
      window.ignoresMouseEvents = true
      window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

      let view = AreaPreviewView(frame: window.contentView!.bounds)
      view.autoresizingMask = [.width, .height]

      window.contentView = view
      previewWindow = window
      previewView = view
      window.orderFront(nil)
    }

    previewWindow?.setFrame(screen.frame, display: true)
    previewView?.setArea(rect)
    currentDisplayID = displayID
    currentRect = rect
  }

  func isShowing(displayID: CGDirectDisplayID, rect: CGRect) -> Bool {
    guard let currentDisplayID, let currentRect else { return false }
    return currentDisplayID == displayID && currentRect.equalTo(rect)
  }

  override func close() {
    previewWindow?.orderOut(nil)
    previewWindow = nil
    previewView = nil
    currentDisplayID = nil
    currentRect = nil
    super.close()
  }
}

private class AreaPreviewView: NSView {
  private var areaRect: CGRect?

  func setArea(_ rect: CGRect) {
    areaRect = rect
    needsDisplay = true
  }

  override func draw(_ dirtyRect: NSRect) {
    guard let areaRect else { return }

    let drawX = areaRect.origin.x
    let drawY = bounds.height - areaRect.origin.y - areaRect.height
    let visibleRect = NSRect(x: drawX, y: drawY, width: areaRect.width, height: areaRect.height)

    let border = NSBezierPath(rect: visibleRect)
    border.lineWidth = 2
    NSColor.white.setStroke()
    border.stroke()
  }
}
