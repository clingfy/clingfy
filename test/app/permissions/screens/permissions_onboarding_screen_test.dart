import 'package:clingfy/core/bridges/native_method_channel.dart';
import 'package:clingfy/app/permissions/permissions_controller.dart';
import 'package:clingfy/app/permissions/screens/permissions_onboarding_screen.dart';
import 'package:clingfy/core/bridges/native_bridge.dart';
import 'package:clingfy/ui/platform/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(NativeChannel.screenRecorder);

  Future<void> mockPermissionStatus({
    required bool screenRecording,
    bool microphone = false,
    bool camera = false,
    bool accessibility = false,
  }) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getPermissionStatus':
              return <String, bool>{
                'screenRecording': screenRecording,
                'microphone': microphone,
                'camera': camera,
                'accessibility': accessibility,
              };
            default:
              return null;
          }
        });
  }

  PermissionsController buildController({
    required bool screenRecording,
    bool microphone = false,
    bool camera = false,
    bool accessibility = false,
  }) {
    return PermissionsController(bridge: NativeBridge.instance)
      ..loading = false
      ..screenRecording = screenRecording
      ..microphone = microphone
      ..camera = camera
      ..accessibility = accessibility;
  }

  Widget buildTestApp(PermissionsController controller) {
    return MaterialApp(
      home: MacosTheme(
        data: MacosThemeData.light(),
        child: PermissionsOnboardingScreen(
          controller: controller,
          onFinished: () {},
        ),
      ),
    );
  }

  Future<void> pumpOnboarding(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pumpPageTransition(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('welcome screen renders current intro content', (tester) async {
    await mockPermissionStatus(screenRecording: false);

    await tester.pumpWidget(
      buildTestApp(buildController(screenRecording: false)),
    );
    await pumpOnboarding(tester);

    expect(find.text('Welcome to Clingfy'), findsOneWidget);
    expect(
      find.text('A quick studio setup and you’re ready to record in minutes.'),
      findsOneWidget,
    );
    expect(
      find.text('Local-first: your recordings stay on your Mac.'),
      findsOneWidget,
    );
    expect(
      find.text('You control permissions anytime in System Settings.'),
      findsOneWidget,
    );
  });

  testWidgets('rail labels match current onboarding flow', (tester) async {
    await mockPermissionStatus(screenRecording: false);

    await tester.pumpWidget(
      buildTestApp(buildController(screenRecording: false)),
    );
    await pumpOnboarding(tester);

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Screen Recording'), findsOneWidget);
    expect(find.text('Mic + Camera'), findsOneWidget);
    expect(find.text('Accessibility'), findsOneWidget);
  });

  testWidgets(
    'screen recording is no longer an onboarding gate between steps',
    (tester) async {
      await mockPermissionStatus(screenRecording: false);

      await tester.pumpWidget(
        buildTestApp(buildController(screenRecording: false)),
      );
      await pumpOnboarding(tester);

      await tester.tap(find.text('Accessibility').first);
      await pumpPageTransition(tester);

      expect(find.text('Cursor Magic (Optional)'), findsOneWidget);
      expect(find.text('Screen Recording (Required)'), findsNothing);
    },
  );

  testWidgets('optional steps remain optional in current flow', (tester) async {
    await mockPermissionStatus(screenRecording: true);

    await tester.pumpWidget(
      buildTestApp(buildController(screenRecording: true)),
    );
    await pumpOnboarding(tester);

    await tester.tap(find.text('Mic + Camera').first);
    await pumpPageTransition(tester);

    expect(find.text('Voice & Face-cam (Optional)'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);

    await tester.tap(find.text('Accessibility').first);
    await pumpPageTransition(tester);

    expect(find.text('Cursor Magic (Optional)'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
  });

  testWidgets(
    'final onboarding action stays available without screen recording',
    (tester) async {
      await mockPermissionStatus(screenRecording: false);

      await tester.pumpWidget(
        buildTestApp(buildController(screenRecording: false)),
      );
      await pumpOnboarding(tester);

      await tester.tap(find.text('Accessibility').first);
      await pumpPageTransition(tester);

      final letsRecordButton = tester.widget<AppButton>(
        find.widgetWithText(AppButton, "Let’s Record! 🚀"),
      );
      expect(letsRecordButton.onPressed, isNotNull);
    },
  );
}
