import 'package:clingfy/app/bootstrap/app_providers.dart';
import 'package:clingfy/app/home/home_page.dart';
import 'package:clingfy/core/bridges/native_bridge.dart';
import 'package:clingfy/app/settings/widgets/about_view.dart';
import 'package:clingfy/app/settings/widgets/app_settings_view.dart';
import 'package:clingfy/app/settings/settings_controller.dart';
import 'package:clingfy/app/shell/platform_app.dart';
import 'package:clingfy/app/permissions/widgets/permissions_gate.dart';
import 'package:clingfy/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../test_helpers/native_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await installCommonNativeMocks(
      screenRecordingGranted: false,
      onboardingSeen: false,
    );
  });

  tearDown(() async {
    await clearCommonNativeMocks();
  });

  Future<SettingsController> pumpPlatformApp(WidgetTester tester) async {
    final nativeBridge = NativeBridge.instance;
    final settingsController = SettingsController(nativeBridge: nativeBridge);
    await settingsController.loadPreferences();

    await tester.pumpWidget(
      AppProviders(
        settingsController: settingsController,
        nativeBridge: nativeBridge,
        child: PlatformApp(
          settingsController: settingsController,
          nativeBridge: nativeBridge,
        ),
      ),
    );

    return settingsController;
  }

  testWidgets('builds PermissionsGate with HomePage child', (tester) async {
    await pumpPlatformApp(tester);
    await tester.pump();

    expect(find.byType(PermissionsGate), findsOneWidget);
    final gate = tester.widget<PermissionsGate>(find.byType(PermissionsGate));
    expect(gate.child, isA<HomePage>());
  });

  testWidgets('settings and about routes still resolve', (tester) async {
    await pumpPlatformApp(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );

    navigator.pushNamed(AppSettingsView.routeName);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AppSettingsView), findsOneWidget);

    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    navigator.pushNamed(AboutView.routeName);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AppSettingsView), findsOneWidget);
    expect(find.text('About'), findsWidgets);
  });

  testWidgets('theme mode updates material and macOS theme state', (
    tester,
  ) async {
    final settingsController = await pumpPlatformApp(tester);
    await tester.pump();

    await settingsController.app.updateThemeMode(ThemeMode.light);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    var context = tester.element(find.byType(PermissionsGate));
    expect(Theme.of(context).brightness, Brightness.light);
    expect(MacosTheme.of(context).brightness, Brightness.light);
    expect(MacosTheme.of(context).primaryColor, clingfyBrandColor);

    await settingsController.app.updateThemeMode(ThemeMode.dark);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    context = tester.element(find.byType(PermissionsGate));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(MacosTheme.of(context).brightness, Brightness.dark);
    expect(MacosTheme.of(context).primaryColor, clingfyBrandColor);
  });
}
