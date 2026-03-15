import CoreGraphics
import Foundation
import ImageIO

final class PreviewBackgroundImageCache {
  private let cache = NSCache<NSString, CGImage>()

  func image(for path: String, canvasRenderSize: CGSize) -> CGImage? {
    let url = URL(fileURLWithPath: path)
    let bucketedLongEdge = bucketedMaxLongEdge(for: canvasRenderSize)
    let cacheKey = "\(path)#\(bucketedLongEdge)" as NSString

    if let cached = cache.object(forKey: cacheKey) {
      return cached
    }

    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceShouldCacheImmediately: true,
      kCGImageSourceThumbnailMaxPixelSize: max(1, bucketedLongEdge),
    ]

    guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
      return nil
    }

    cache.setObject(image, forKey: cacheKey)
    return image
  }

  func clear() {
    cache.removeAllObjects()
  }

  private func bucketedMaxLongEdge(for size: CGSize) -> Int {
    let longEdge = max(size.width, size.height)
    let bucketed = max(64, Int((longEdge / 64.0).rounded(.up) * 64.0))
    return bucketed
  }
}
