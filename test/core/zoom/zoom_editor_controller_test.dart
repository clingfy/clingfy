import 'package:clingfy/core/bridges/native_bridge.dart';
import 'package:clingfy/core/zoom/zoom_editor_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers/native_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await clearCommonNativeMocks();
  });

  testWidgets('default add mode is off', (tester) async {
    final harness = await _createHarness(tester);

    expect(harness.controller.addMode, ZoomAddMode.off);
    expect(harness.controller.addModeEnabled, isFalse);
    expect(harness.controller.stickyAddModeEnabled, isFalse);
  });

  testWidgets('toggleAddMode enters one-shot mode from off', (tester) async {
    final harness = await _createHarness(tester);

    harness.controller.toggleAddMode();
    await tester.pump();

    expect(harness.controller.addMode, ZoomAddMode.oneShot);
    expect(harness.controller.addModeEnabled, isTrue);
    expect(harness.controller.stickyAddModeEnabled, isFalse);
  });

  testWidgets('enterStickyAddMode enters sticky mode from off', (tester) async {
    final harness = await _createHarness(tester);

    harness.controller.enterStickyAddMode();
    await tester.pump();

    expect(harness.controller.addMode, ZoomAddMode.sticky);
    expect(harness.controller.addModeEnabled, isTrue);
    expect(harness.controller.stickyAddModeEnabled, isTrue);
  });

  testWidgets('toggleStickyAddMode downgrades sticky mode to one-shot', (
    tester,
  ) async {
    final harness = await _createHarness(tester);

    harness.controller.enterStickyAddMode();
    harness.controller.toggleStickyAddMode();
    await tester.pump();

    expect(harness.controller.addMode, ZoomAddMode.oneShot);
    expect(harness.controller.addModeEnabled, isTrue);
    expect(harness.controller.stickyAddModeEnabled, isFalse);
  });

  testWidgets('commitDraft exits one-shot add mode after creating a segment', (
    tester,
  ) async {
    final harness = await _createHarness(tester);

    harness.controller.enterOneShotAddMode();
    harness.controller.updateDraft(120, 460);
    harness.controller.commitDraft();
    await tester.pump();

    expect(harness.controller.addMode, ZoomAddMode.off);
    expect(harness.controller.manualSegments, hasLength(1));
    expect(harness.controller.selectedCount, 1);
  });

  testWidgets('commitDraft keeps sticky add mode active after creation', (
    tester,
  ) async {
    final harness = await _createHarness(tester);

    harness.controller.enterStickyAddMode();
    harness.controller.updateDraft(120, 460);
    harness.controller.commitDraft();
    await tester.pump();

    expect(harness.controller.addMode, ZoomAddMode.sticky);
    expect(harness.controller.manualSegments, hasLength(1));
    expect(harness.controller.selectedCount, 1);
  });

  testWidgets('handleEscapeAction clears draft and exits one-shot add mode', (
    tester,
  ) async {
    final harness = await _createHarness(tester);

    harness.controller.enterOneShotAddMode();
    harness.controller.updateDraft(120, 460);

    expect(harness.controller.draftSegment, isNotNull);

    final handled = harness.controller.handleEscapeAction();
    await tester.pump();

    expect(handled, isTrue);
    expect(harness.controller.draftSegment, isNull);
    expect(harness.controller.addMode, ZoomAddMode.off);
  });

  testWidgets('handleEscapeAction clears draft and exits sticky add mode', (
    tester,
  ) async {
    final harness = await _createHarness(tester);

    harness.controller.enterStickyAddMode();
    harness.controller.updateDraft(120, 460);

    final handled = harness.controller.handleEscapeAction();
    await tester.pump();

    expect(handled, isTrue);
    expect(harness.controller.draftSegment, isNull);
    expect(harness.controller.addMode, ZoomAddMode.off);
  });

  testWidgets('sticky mode keeps the newly created segment selected', (
    tester,
  ) async {
    final harness = await _createHarness(tester);

    harness.controller.enterStickyAddMode();
    harness.controller.updateDraft(100, 500);
    harness.controller.commitDraft();
    await tester.pump();

    final createdSegment = harness.controller.manualSegments.single;
    expect(harness.controller.primarySelectedSegmentId, createdSegment.id);
    expect(harness.controller.selectedSegmentIds, {createdSegment.id});
  });

  testWidgets('undo behavior remains unchanged with new add modes', (
    tester,
  ) async {
    final harness = await _createHarness(tester);

    harness.controller.enterOneShotAddMode();
    harness.controller.updateDraft(100, 500);
    harness.controller.commitDraft();
    await tester.pump();

    expect(harness.controller.canUndo, isTrue);
    expect(harness.controller.manualSegments, hasLength(1));

    harness.controller.undo();
    await tester.pump();

    expect(harness.controller.canUndo, isFalse);
    expect(harness.controller.manualSegments, isEmpty);
    expect(harness.controller.addMode, ZoomAddMode.off);
  });
}

Future<_ZoomEditorHarness> _createHarness(
  WidgetTester tester, {
  List<Map<String, Object?>> autoSegments = const [],
  List<Map<String, Object?>> manualSegments = const [],
}) async {
  await installCommonNativeMocks();
  final calls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(screenRecorderChannel, (call) async {
    calls.add(call);
    switch (call.method) {
      case 'getZoomSegments':
        return autoSegments;
      case 'getManualZoomSegments':
        return manualSegments;
      case 'saveManualZoomSegments':
        return true;
      case 'previewSetZoomSegments':
        return null;
      default:
        return null;
    }
  });

  final controller = ZoomEditorController(
    nativeBridge: NativeBridge.instance,
    videoPath: '/tmp/demo.mov',
    durationMs: 2000,
  );
  await controller.init();
  addTearDown(controller.dispose);

  return _ZoomEditorHarness(controller: controller, calls: calls);
}

class _ZoomEditorHarness {
  const _ZoomEditorHarness({required this.controller, required this.calls});

  final ZoomEditorController controller;
  final List<MethodCall> calls;
}
