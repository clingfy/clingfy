import Cocoa
import FlutterMacOS

final class MenuBarController: NSObject, NSMenuDelegate {
  private var statusItem: NSStatusItem!
  private weak var recorder: ScreenRecorderFacade?
  private var onOpenApp: (() -> Void)?
  private var onRequestToggle: (() -> Void)?

  // We keep track of recording state locally to toggle correctly
  private var isRecording = false

  init(
    recorder: ScreenRecorderFacade,
    onOpenApp: @escaping () -> Void,
    onRequestToggle: @escaping () -> Void
  ) {
    self.recorder = recorder
    self.onOpenApp = onOpenApp
    self.onRequestToggle = onRequestToggle
    super.init()

    // Create the status item in the system menu bar
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.behavior = .terminationOnRemoval

    if let button = statusItem.button {
      // Set initial icon
      button.image = drawIcon(isRecording: false)
      button.imagePosition = .imageOnly

      // Handle click events
      button.target = self
      button.action = #selector(statusBarItemClicked(_:))
      button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    // Build the menu
    let menu = NSMenu()
    menu.delegate = self
    statusItem.menu = menu
  }

  // MARK: - Public API

  func update(isRecording: Bool) {
    self.isRecording = isRecording
    if let button = statusItem.button {
      button.image = drawIcon(isRecording: isRecording)
    }
  }

  // MARK: - Actions

  @objc private func statusBarItemClicked(_ sender: NSStatusBarButton) {
    let event = NSApp.currentEvent
    if event?.type == .rightMouseUp || (event?.modifierFlags.contains(.control) == true) {
      statusItem.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    } else {
      // Left click: Toggle
      toggleRecording()
    }
  }

  private func toggleRecording() {
    onRequestToggle?()
  }

  // MARK: - Menu Construction
  func menuNeedsUpdate(_ menu: NSMenu) {
    menu.removeAllItems()

    // Use cached localized strings from NativeStringsStore (pushed from Flutter)
    let strings = NativeStringsStore.shared

    let startItem = NSMenuItem(
      title: strings.menuStartRecording, action: #selector(startClicked), keyEquivalent: "")
    startItem.target = self
    if isRecording { startItem.isHidden = true }
    menu.addItem(startItem)

    let stopItem = NSMenuItem(
      title: strings.menuStopRecording, action: #selector(stopClicked), keyEquivalent: "")
    stopItem.target = self
    if !isRecording { stopItem.isHidden = true }
    menu.addItem(stopItem)

    menu.addItem(NSMenuItem.separator())

    let openItem = NSMenuItem(
      title: strings.menuOpenApp, action: #selector(openAppClicked), keyEquivalent: "o")
    openItem.target = self
    menu.addItem(openItem)

    menu.addItem(NSMenuItem.separator())

    let quitItem = NSMenuItem(
      title: strings.menuQuit, action: #selector(quitClicked), keyEquivalent: "q")
    quitItem.target = self
    menu.addItem(quitItem)
  }

  @objc private func startClicked() {
    guard !isRecording else { return }
    onRequestToggle?()
  }

  @objc private func stopClicked() {
    guard isRecording else { return }
    onRequestToggle?()
  }

  @objc private func openAppClicked() {
    onOpenApp?()
    NSApp.activate(ignoringOtherApps: true)
  }

  @objc private func quitClicked() {
    NSApp.terminate(nil)
  }

  // MARK: - Icon Drawing

  private func drawIcon(isRecording: Bool) -> NSImage {
    let size = NSSize(width: 18, height: 18)
    let img = NSImage(size: size)
    img.isTemplate = true  // Adapts to dark/light mode automatically

    img.lockFocus()
    defer { img.unlockFocus() }

    let ctx = NSGraphicsContext.current?.cgContext

    // Circle rect
    let rect = CGRect(x: 1, y: 1, width: 16, height: 16)
    let path = CGPath(ellipseIn: rect, transform: nil)

    if isRecording {
      // Filled circle
      ctx?.addPath(path)
      ctx?.setFillColor(NSColor.labelColor.cgColor)
      ctx?.fillPath()

      // Template images use alpha as the mask, so clearing creates the stop glyph cutout.
      ctx?.setBlendMode(.clear)
      let s: CGFloat = 6
      let square = CGRect(x: (18 - s) / 2, y: (18 - s) / 2, width: s, height: s)
      ctx?.fill(square)
      ctx?.setBlendMode(.normal)
    } else {
      // Stroked circle
      ctx?.addPath(path)
      ctx?.setLineWidth(2.0)
      ctx?.setStrokeColor(NSColor.labelColor.cgColor)
      ctx?.strokePath()

      // small centered dot for 'record' feel? or just empty circle.
      // Let's do a solid circle of radius 4 in the middle
      let dotS: CGFloat = 6
      let dotRect = CGRect(x: (18 - dotS) / 2, y: (18 - dotS) / 2, width: dotS, height: dotS)
      ctx?.addPath(CGPath(ellipseIn: dotRect, transform: nil))
      ctx?.setFillColor(NSColor.labelColor.cgColor)
      ctx?.fillPath()
    }

    return img
  }
}
