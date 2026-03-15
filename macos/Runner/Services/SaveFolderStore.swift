import Foundation

final class SaveFolderStore {
  private let ud = UserDefaults.standard
  private var scopedURL: URL?
  private var accessCount = 0

  static func defaultSaveFolderURL() -> URL {
    let base =
      FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first
      ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Movies")
    return base.appendingPathComponent("Clingfy", isDirectory: true)
  }

  func resolveFolderURL() -> URL {
    guard let data = ud.data(forKey: PrefKey.saveFolderBookmark) else {
      return SaveFolderStore.defaultSaveFolderURL()
    }
    var stale = false
    do {
      let url = try URL(
        resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI], relativeTo: nil,
        bookmarkDataIsStale: &stale)
      if stale { try persist(url) }
      return url
    } catch {
      ud.removeObject(forKey: PrefKey.saveFolderBookmark)
      return SaveFolderStore.defaultSaveFolderURL()
    }
  }

  func persist(_ url: URL) throws {
    let data = try url.bookmarkData(
      options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
    ud.set(data, forKey: PrefKey.saveFolderBookmark)
  }

  @discardableResult
  func beginAccess() -> URL {
    let url = resolveFolderURL()
    if url.startAccessingSecurityScopedResource() {
      scopedURL = url
      accessCount += 1
    }
    return url
  }

  func endAccess() {
    guard let url = scopedURL, accessCount > 0 else { return }
    accessCount -= 1
    if accessCount == 0 {
      url.stopAccessingSecurityScopedResource()
      scopedURL = nil
    }
  }
}
