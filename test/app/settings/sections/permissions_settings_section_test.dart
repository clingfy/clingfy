import 'package:clingfy/core/bridges/native_method_channel.dart';
import 'package:clingfy/l10n/app_localizations.dart';
import 'package:clingfy/app/settings/sections/permissions_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(NativeChannel.screenRecorder);

  late Map<String, bool> status;
  late List<MethodCall> calls;

  Widget buildTestApp() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) =>
          MacosTheme(data: MacosThemeData.light(), child: child!),
      home: const Scaffold(body: PermissionsSettingsSection()),
    );
  }

  Future<void> pumpSection(WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Iterable<MethodCall> methodCalls(String method) =>
      calls.where((call) => call.method == method);

  Finder findInCard(String cardId, Finder matching) {
    return find.descendant(
      of: find.byKey(ValueKey('permission-card-$cardId')),
      matching: matching,
    );
  }

  setUp(() {
    status = <String, bool>{
      'screenRecording': true,
      'microphone': false,
      'camera': true,
      'accessibility': false,
    };
    calls = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);

          switch (call.method) {
            case 'getPermissionStatus':
              return Map<String, bool>.from(status);
            case 'requestScreenRecordingPermission':
              status['screenRecording'] = true;
              return true;
            case 'requestMicrophonePermission':
              status['microphone'] = true;
              return true;
            case 'requestCameraPermission':
              status['camera'] = true;
              return true;
            case 'openAccessibilitySettings':
              return null;
            case 'openScreenRecordingSettings':
              return null;
            case 'openSystemSettings':
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('renders all permission cards, pills, and help notice', (
    tester,
  ) async {
    await pumpSection(tester);

    expect(
      find.byKey(const ValueKey('permission-card-screenRecording')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('permission-card-microphone')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('permission-card-camera')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('permission-card-accessibility')),
      findsOneWidget,
    );

    expect(find.text('Screen Recording'), findsOneWidget);
    expect(find.text('Microphone'), findsOneWidget);
    expect(find.text('Camera'), findsWidgets);
    expect(find.text('Accessibility'), findsOneWidget);

    expect(find.text('Granted'), findsNWidgets(2));
    expect(find.text('Not granted'), findsNWidgets(2));
    expect(find.text('Required'), findsOneWidget);
    expect(find.text('Optional'), findsNWidgets(3));
    expect(
      find.text(
        'If you change a permission in System Settings, return to Clingfy and refresh this page to see the latest status.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('grant access buttons call the correct native methods', (
    tester,
  ) async {
    status = <String, bool>{
      'screenRecording': false,
      'microphone': false,
      'camera': false,
      'accessibility': false,
    };

    await pumpSection(tester);

    await tapVisible(
      tester,
      find.byKey(const ValueKey('permission-primary-screenRecording')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('permission-primary-microphone')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('permission-primary-camera')),
    );

    expect(methodCalls('requestScreenRecordingPermission'), hasLength(1));
    expect(methodCalls('requestMicrophonePermission'), hasLength(1));
    expect(methodCalls('requestCameraPermission'), hasLength(1));
  });

  testWidgets('open settings actions call the correct native methods', (
    tester,
  ) async {
    status = <String, bool>{
      'screenRecording': false,
      'microphone': false,
      'camera': false,
      'accessibility': false,
    };

    await pumpSection(tester);

    await tapVisible(
      tester,
      find.byKey(const ValueKey('permission-secondary-screenRecording')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('permission-secondary-microphone')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('permission-secondary-camera')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('permission-primary-accessibility')),
    );

    expect(methodCalls('openScreenRecordingSettings'), hasLength(1));
    expect(methodCalls('openAccessibilitySettings'), hasLength(1));

    final openSystemSettingsCalls = methodCalls('openSystemSettings').toList();
    expect(openSystemSettingsCalls, hasLength(2));
    expect(
      openSystemSettingsCalls.any(
        (call) => (call.arguments as Map)['pane'] == 'microphone',
      ),
      isTrue,
    );
    expect(
      openSystemSettingsCalls.any(
        (call) => (call.arguments as Map)['pane'] == 'camera',
      ),
      isTrue,
    );
  });

  testWidgets('refresh status button fetches permission state again', (
    tester,
  ) async {
    await pumpSection(tester);

    final initialRefreshCalls = methodCalls('getPermissionStatus').length;

    await tester.tap(find.byKey(const ValueKey('permissions-refresh')));
    await tester.pumpAndSettle();

    expect(methodCalls('getPermissionStatus').length, initialRefreshCalls + 1);
  });

  testWidgets('resumed lifecycle refresh updates visible status', (
    tester,
  ) async {
    status = <String, bool>{
      'screenRecording': false,
      'microphone': false,
      'camera': false,
      'accessibility': false,
    };

    await pumpSection(tester);

    expect(
      findInCard('screenRecording', find.text('Not granted')),
      findsOneWidget,
    );
    expect(findInCard('screenRecording', find.text('Granted')), findsNothing);

    status['screenRecording'] = true;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(findInCard('screenRecording', find.text('Granted')), findsOneWidget);
    expect(methodCalls('getPermissionStatus').length, greaterThanOrEqualTo(2));
  });
}
