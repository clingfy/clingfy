import 'package:clingfy/core/permissions/models/permission_status_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromStatusMap fills known permissions and defaults missing ones', () {
    final snapshot = PermissionStatusSnapshot.fromStatusMap(const {
      'screenRecording': true,
      'camera': true,
    });

    expect(snapshot.screenRecording, isTrue);
    expect(snapshot.microphone, isFalse);
    expect(snapshot.camera, isTrue);
    expect(snapshot.accessibility, isFalse);
  });
}
