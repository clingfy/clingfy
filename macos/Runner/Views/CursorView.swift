import AVFoundation
import FlutterMacOS

final class CursorView: NSView {
  private let ring = CAShapeLayer()
  private let clickRing = CAShapeLayer()

  var ringSize: CGFloat = 60 {
    didSet { needsLayout = true }
  }
  var baseColor: NSColor = .systemYellow.withAlphaComponent(0.25) {
    didSet { ring.fillColor = baseColor.cgColor }
  }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    wantsLayer = true
    ring.fillColor = baseColor.cgColor
    layer?.addSublayer(ring)

    clickRing.fillColor = NSColor.clear.cgColor
    clickRing.strokeColor = NSColor.systemYellow.cgColor
    clickRing.lineWidth = 3
    clickRing.opacity = 0
    layer?.addSublayer(clickRing)
  }

  required init?(coder: NSCoder) { fatalError() }

  override func layout() {
    super.layout()
    let d = ringSize
    let rect = CGRect(x: (bounds.width - d) / 2, y: (bounds.height - d) / 2, width: d, height: d)
    ring.path = CGPath(ellipseIn: rect, transform: nil)
    clickRing.path = CGPath(ellipseIn: rect.insetBy(dx: -2, dy: -2), transform: nil)
  }

  func pulseClick() {
    clickRing.removeAllAnimations()
    clickRing.opacity = 1
    let scale = CABasicAnimation(keyPath: "transform.scale")
    scale.fromValue = 1.0
    scale.toValue = 1.35
    let fade = CABasicAnimation(keyPath: "opacity")
    fade.fromValue = 1.0
    fade.toValue = 0.0
    let group = CAAnimationGroup()
    group.animations = [scale, fade]
    group.duration = 0.35
    group.timingFunction = CAMediaTimingFunction(name: .easeOut)
    group.isRemovedOnCompletion = true
    clickRing.add(group, forKey: "pulse")
  }
}
