import 'package:clingfy/core/permissions/models/recording_start_preflight.dart';
import 'package:clingfy/app/permissions/widgets/start_recording_permission_dialog.dart';
import 'package:clingfy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDialog(
    WidgetTester tester, {
    required RecordingStartPreflight preflight,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            MacosTheme(data: MacosThemeData.light(), child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                StartRecordingPermissionDialog.show(
                  context,
                  preflight: preflight,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('dialog with hard blocker shows Grant permissions and Cancel', (
    tester,
  ) async {
    await pumpDialog(
      tester,
      preflight: const RecordingStartPreflight(
        intent: RecordingStartIntent(
          needsScreenRecording: true,
          needsMicrophone: false,
          needsCamera: false,
          needsAccessibility: false,
        ),
        missingHard: [MissingPermissionKind.screenRecording],
        missingOptional: [],
      ),
    );

    expect(find.text('Grant permissions'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Record without missing features'), findsNothing);
    expect(find.text('Screen Recording'), findsOneWidget);
  });

  testWidgets(
    'dialog with optional gaps shows grant, record without, and cancel',
    (tester) async {
      await pumpDialog(
        tester,
        preflight: const RecordingStartPreflight(
          intent: RecordingStartIntent(
            needsScreenRecording: true,
            needsMicrophone: true,
            needsCamera: true,
            needsAccessibility: true,
          ),
          missingHard: [],
          missingOptional: [
            MissingPermissionKind.camera,
            MissingPermissionKind.microphone,
            MissingPermissionKind.accessibility,
          ],
        ),
      );

      expect(find.text('Grant permissions'), findsOneWidget);
      expect(find.text('Record without missing features'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    },
  );

  testWidgets(
    'dialog lists Camera for Face Cam, Microphone for Voice, and Accessibility for Cursor Highlight',
    (tester) async {
      await pumpDialog(
        tester,
        preflight: const RecordingStartPreflight(
          intent: RecordingStartIntent(
            needsScreenRecording: true,
            needsMicrophone: true,
            needsCamera: true,
            needsAccessibility: true,
          ),
          missingHard: [],
          missingOptional: [
            MissingPermissionKind.camera,
            MissingPermissionKind.microphone,
            MissingPermissionKind.accessibility,
          ],
        ),
      );

      expect(find.text('Camera for Face Cam'), findsOneWidget);
      expect(find.text('Microphone for Voice'), findsOneWidget);
      expect(find.text('Accessibility for Cursor Highlight'), findsOneWidget);
    },
  );
}
