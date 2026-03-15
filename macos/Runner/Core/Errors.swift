import FlutterMacOS

func flutterError(_ code: String, _ msg: String) -> FlutterError {
  FlutterError(code: code, message: msg, details: nil)
}
