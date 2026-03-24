import 'dart:async';

import 'package:clingfy/app/settings/sections/storage_settings_section.dart';
import 'package:clingfy/app/settings/settings_controller.dart';
import 'package:clingfy/core/bridges/native_bridge.dart';
import 'package:clingfy/core/bridges/native_method_channel.dart';
import 'package:clingfy/l10n/app_localizations.dart';
import 'package:clingfy/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(NativeChannel.screenRecorder);

  Widget buildTestApp(SettingsController settings) {
    return MaterialApp(
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MacosTheme(
        data: buildMacosTheme(Theme.of(context).brightness),
        child: child!,
      ),
      home: Scaffold(
        body: StorageSettingsSection(
          controller: settings,
          showDeveloperTools: true,
        ),
      ),
    );
  }

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('shows loading while snapshot is in flight', (tester) async {
    final completer = Completer<Map<String, dynamic>>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getStorageSnapshot') {
            return completer.future;
          }
          return null;
        });

    final settings = SettingsController(nativeBridge: NativeBridge.instance);
    await tester.pumpWidget(buildTestApp(settings));
    await tester.pump();

    expect(find.text('Loading…'), findsOneWidget);

    completer.complete(<String, dynamic>{
      'systemTotalBytes': 500 * 1024 * 1024 * 1024,
      'systemAvailableBytes': 200 * 1024 * 1024 * 1024,
      'recordingsBytes': 4 * 1024 * 1024,
      'tempBytes': 2 * 1024 * 1024,
      'logsBytes': 512 * 1024,
      'recordingsPath': '/tmp/recordings',
      'tempPath': '/tmp/temp',
      'logsPath': '/tmp/logs',
      'warningThresholdBytes': 20 * 1024 * 1024 * 1024,
      'criticalThresholdBytes': 10 * 1024 * 1024 * 1024,
    });
    await tester.pumpAndSettle();

    expect(find.text('Healthy'), findsWidgets);
  });

  testWidgets('renders warning status when free space is low', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getStorageSnapshot') {
            return <String, dynamic>{
              'systemTotalBytes': 500 * 1024 * 1024 * 1024,
              'systemAvailableBytes': 15 * 1024 * 1024 * 1024,
              'recordingsBytes': 4 * 1024 * 1024,
              'tempBytes': 2 * 1024 * 1024,
              'logsBytes': 512 * 1024,
              'recordingsPath': '/tmp/recordings',
              'tempPath': '/tmp/temp',
              'logsPath': '/tmp/logs',
              'warningThresholdBytes': 20 * 1024 * 1024 * 1024,
              'criticalThresholdBytes': 10 * 1024 * 1024 * 1024,
            };
          }
          return null;
        });

    final settings = SettingsController(nativeBridge: NativeBridge.instance);
    await tester.pumpWidget(buildTestApp(settings));
    await tester.pumpAndSettle();

    expect(find.text('Warning'), findsWidgets);
    expect(
      find.text('Free space is getting low. Long recordings may fail.'),
      findsOneWidget,
    );
  });

  testWidgets('renders storage charts above the related stats', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getStorageSnapshot') {
            return <String, dynamic>{
              'systemTotalBytes': 500 * 1024 * 1024 * 1024,
              'systemAvailableBytes': 200 * 1024 * 1024 * 1024,
              'recordingsBytes': 4 * 1024 * 1024,
              'tempBytes': 2 * 1024 * 1024,
              'logsBytes': 512 * 1024,
              'recordingsPath': '/tmp/recordings',
              'tempPath': '/tmp/temp',
              'logsPath': '/tmp/logs',
              'warningThresholdBytes': 20 * 1024 * 1024 * 1024,
              'criticalThresholdBytes': 10 * 1024 * 1024 * 1024,
            };
          }
          return null;
        });

    final settings = SettingsController(nativeBridge: NativeBridge.instance);
    await tester.pumpWidget(buildTestApp(settings));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('storage_system_chart')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('storage_system_chart'))).dy,
      lessThan(tester.getTopLeft(find.text('Status')).dy),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('storage_clingfy_chart')), findsOneWidget);
  });

  testWidgets('renders critical status when free space is below threshold', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getStorageSnapshot') {
            return <String, dynamic>{
              'systemTotalBytes': 500 * 1024 * 1024 * 1024,
              'systemAvailableBytes': 5 * 1024 * 1024 * 1024,
              'recordingsBytes': 4 * 1024 * 1024,
              'tempBytes': 2 * 1024 * 1024,
              'logsBytes': 512 * 1024,
              'recordingsPath': '/tmp/recordings',
              'tempPath': '/tmp/temp',
              'logsPath': '/tmp/logs',
              'warningThresholdBytes': 20 * 1024 * 1024 * 1024,
              'criticalThresholdBytes': 10 * 1024 * 1024 * 1024,
            };
          }
          return null;
        });

    final settings = SettingsController(nativeBridge: NativeBridge.instance);
    await tester.pumpWidget(buildTestApp(settings));
    await tester.pumpAndSettle();

    expect(find.text('Critical'), findsWidgets);
    expect(
      find.text('Recording is blocked until more disk space is available.'),
      findsOneWidget,
    );
  });

  testWidgets('renders error state when storage snapshot cannot be loaded', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'BROKEN');
        });

    final settings = SettingsController(nativeBridge: NativeBridge.instance);
    await tester.pumpWidget(buildTestApp(settings));
    await tester.pumpAndSettle();

    expect(find.text('Storage action failed.'), findsOneWidget);
    expect(find.text('Refresh'), findsWidgets);
  });

  testWidgets('hides actions and paths in production mode', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getStorageSnapshot') {
            return <String, dynamic>{
              'systemTotalBytes': 500 * 1024 * 1024 * 1024,
              'systemAvailableBytes': 200 * 1024 * 1024 * 1024,
              'recordingsBytes': 4 * 1024 * 1024,
              'tempBytes': 2 * 1024 * 1024,
              'logsBytes': 512 * 1024,
              'recordingsPath': '/tmp/recordings',
              'tempPath': '/tmp/temp',
              'logsPath': '/tmp/logs',
              'warningThresholdBytes': 20 * 1024 * 1024 * 1024,
              'criticalThresholdBytes': 10 * 1024 * 1024 * 1024,
            };
          }
          return null;
        });

    final settings = SettingsController(nativeBridge: NativeBridge.instance);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MacosTheme(
          data: buildMacosTheme(Theme.of(context).brightness),
          child: child!,
        ),
        home: Scaffold(
          body: StorageSettingsSection(
            controller: settings,
            showDeveloperTools: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Actions'), findsNothing);
    expect(find.text('Paths'), findsNothing);
    expect(find.text('Open recordings folder'), findsNothing);
    expect(find.text('Open temp folder'), findsNothing);
  });

  testWidgets('auto refreshes while the section stays visible', (tester) async {
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getStorageSnapshot') {
            calls += 1;
            return <String, dynamic>{
              'systemTotalBytes': 500 * 1024 * 1024 * 1024,
              'systemAvailableBytes': 200 * 1024 * 1024 * 1024,
              'recordingsBytes': 4 * 1024 * 1024,
              'tempBytes': 2 * 1024 * 1024,
              'logsBytes': 512 * 1024,
              'recordingsPath': '/tmp/recordings',
              'tempPath': '/tmp/temp',
              'logsPath': '/tmp/logs',
              'warningThresholdBytes': 20 * 1024 * 1024 * 1024,
              'criticalThresholdBytes': 10 * 1024 * 1024 * 1024,
            };
          }
          return null;
        });

    final settings = SettingsController(nativeBridge: NativeBridge.instance);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MacosTheme(
          data: buildMacosTheme(Theme.of(context).brightness),
          child: child!,
        ),
        home: Scaffold(
          body: StorageSettingsSection(
            controller: settings,
            autoRefreshInterval: const Duration(seconds: 1),
            showDeveloperTools: true,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();
    expect(calls, 1);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(calls, greaterThanOrEqualTo(2));
  });
}
