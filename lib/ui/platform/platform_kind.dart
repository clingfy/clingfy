import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

enum PlatformKind { macos, windows, web, linux, other }

bool isWindows() {
  return !kIsWeb && currentPlatformKind() == PlatformKind.windows;
}

bool isMac() {
  return !kIsWeb && currentPlatformKind() == PlatformKind.macos;
}

PlatformKind currentPlatformKind() {
  if (Platform.isMacOS) {
    return PlatformKind.macos;
  }
  if (Platform.isWindows) {
    return PlatformKind.windows;
  }
  if (kIsWeb) {
    return PlatformKind.other;
  }
  return PlatformKind.other;
}
