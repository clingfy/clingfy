import AppKit

final class CursorHighlighter {
  private var window: NSWindow?
  private var view = CursorView()
  private var mouseMoveGlobal: Any?
  private var mouseDownGlobal: Any?
  private var mouseMoveLocal: Any?
  private var mouseDownLocal: Any?

  var ringSize: CGFloat = 60
  var baseColor = NSColor.systemYellow.withAlphaComponent(0.25)

  func start() {
    guard mouseMoveGlobal == nil && mouseMoveLocal == nil else { return }
    if window == nil { setUpWindow() }
    repositionAtCurrentMouse()
    window?.orderFront(nil)

    mouseMoveGlobal = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] e in
      self?.reposition(e)
    }
    mouseDownGlobal = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) {
      [weak self] _ in
      self?.view.pulseClick()
    }
    mouseMoveLocal = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] e in
      self?.reposition(e)
      return e
    }
    mouseDownLocal = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] e in
      self?.view.pulseClick()
      return e
    }
  }

  func stop() {
    if let m = mouseMoveGlobal {
      NSEvent.removeMonitor(m)
      mouseMoveGlobal = nil
    }
    if let m = mouseDownGlobal {
      NSEvent.removeMonitor(m)
      mouseDownGlobal = nil
    }
    if let m = mouseMoveLocal {
      NSEvent.removeMonitor(m)
      mouseMoveLocal = nil
    }
    if let m = mouseDownLocal {
      NSEvent.removeMonitor(m)
      mouseDownLocal = nil
    }
    window?.orderOut(nil)
    window = nil
  }

  private func setUpWindow() {
    let size = max(ringSize, 24)
    let panel = NSPanel(
      contentRect: .init(x: 0, y: 0, width: size * 2, height: size * 2),
      styleMask: [.nonactivatingPanel, .borderless], backing: .buffered, defer: false)
    panel.isFloatingPanel = true
    panel.hidesOnDeactivate = false
    panel.becomesKeyOnlyIfNeeded = true
    panel.level = .screenSaver
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.ignoresMouseEvents = true
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]

    view.frame = panel.frame
    view.ringSize = ringSize
    view.baseColor = baseColor
    panel.contentView = view
    window = panel
    panel.orderFrontRegardless()
  }

  private func repositionAtCurrentMouse() {
    guard let win = window else { return }
    let loc = NSEvent.mouseLocation
    let origin = CGPoint(x: loc.x - win.frame.width / 2, y: loc.y - win.frame.height / 2)
    win.setFrame(.init(origin: origin, size: win.frame.size), display: false)
  }

  private func reposition(_ e: NSEvent) { repositionAtCurrentMouse() }
}
