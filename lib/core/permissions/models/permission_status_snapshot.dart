class PermissionStatusSnapshot {
  const PermissionStatusSnapshot({
    this.screenRecording = false,
    this.microphone = false,
    this.camera = false,
    this.accessibility = false,
  });

  factory PermissionStatusSnapshot.fromStatusMap(Map<String, bool> status) {
    return PermissionStatusSnapshot(
      screenRecording: status['screenRecording'] ?? false,
      microphone: status['microphone'] ?? false,
      camera: status['camera'] ?? false,
      accessibility: status['accessibility'] ?? false,
    );
  }

  final bool screenRecording;
  final bool microphone;
  final bool camera;
  final bool accessibility;

  PermissionStatusSnapshot copyWith({
    bool? screenRecording,
    bool? microphone,
    bool? camera,
    bool? accessibility,
  }) {
    return PermissionStatusSnapshot(
      screenRecording: screenRecording ?? this.screenRecording,
      microphone: microphone ?? this.microphone,
      camera: camera ?? this.camera,
      accessibility: accessibility ?? this.accessibility,
    );
  }
}
