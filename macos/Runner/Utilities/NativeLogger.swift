import FlutterMacOS
import Foundation

class NativeLogger {
  static var channel: FlutterMethodChannel?

  static func configure(with channel: FlutterMethodChannel) {
    self.channel = channel
  }

  static func d(
    _ category: String, _ message: String, context: [String: Any]? = nil, file: String = #file,
    line: Int = #line
  ) {
    send(
      level: "DEBUG", category: category, message: message, context: context, file: file, line: line
    )
  }

  static func i(
    _ category: String, _ message: String, context: [String: Any]? = nil, file: String = #file,
    line: Int = #line
  ) {
    send(
      level: "INFO", category: category, message: message, context: context, file: file, line: line)
  }

  static func w(
    _ category: String, _ message: String, context: [String: Any]? = nil, file: String = #file,
    line: Int = #line
  ) {
    send(
      level: "WARNING", category: category, message: message, context: context, file: file,
      line: line)
  }

  static func e(
    _ category: String, _ message: String, context: [String: Any]? = nil, file: String = #file,
    line: Int = #line
  ) {
    send(
      level: "ERROR", category: category, message: message, context: context, file: file, line: line
    )
  }

  private static func send(
    level: String, category: String, message: String, context: [String: Any]?, file: String,
    line: Int
  ) {
    let filename = (file as NSString).lastPathComponent

    let payload: [String: Any] = [
      "ts": ISO8601DateFormatter().string(from: Date()),
      "level": level,
      "category": category,
      "message": message,
      "file": filename,
      "line": line,
      "context": context ?? [:],
    ]

    // Always NSLog for Xcode visibility
    // NSLog("[\(category)] [\(level)] \(message)")

    DispatchQueue.main.async {
      channel?.invokeMethod("log", arguments: payload)
    }
  }
}
