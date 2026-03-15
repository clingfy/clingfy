enum MissingPermissionKind {
  screenRecording,
  microphone,
  camera,
  accessibility,
}

class RecordingStartIntent {
  const RecordingStartIntent({
    required this.needsScreenRecording,
    required this.needsMicrophone,
    required this.needsCamera,
    required this.needsAccessibility,
  });

  final bool needsScreenRecording;
  final bool needsMicrophone;
  final bool needsCamera;
  final bool needsAccessibility;
}

class RecordingStartPreflight {
  const RecordingStartPreflight({
    required this.intent,
    required this.missingHard,
    required this.missingOptional,
  });

  final RecordingStartIntent intent;
  final List<MissingPermissionKind> missingHard;
  final List<MissingPermissionKind> missingOptional;

  bool get isClear => missingHard.isEmpty && missingOptional.isEmpty;
  bool get hasHardBlocker => missingHard.isNotEmpty;
  bool get hasOptionalGaps => missingOptional.isNotEmpty;
}

class RecordingStartOverrides {
  const RecordingStartOverrides({
    this.disableMicrophone = false,
    this.disableCameraOverlay = false,
    this.disableCursorHighlight = false,
  });

  final bool disableMicrophone;
  final bool disableCameraOverlay;
  final bool disableCursorHighlight;
}
