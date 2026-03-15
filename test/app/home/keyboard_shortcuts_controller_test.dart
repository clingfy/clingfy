import 'package:clingfy/app/home/keyboard_shortcuts_controller.dart';
import 'package:clingfy/l10n/app_localizations.dart';
import 'package:clingfy/app/settings/shortcuts/shortcut_config.dart';
import 'package:clingfy/core/bridges/native_bridge.dart';
import 'package:clingfy/app/settings/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers/native_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await installCommonNativeMocks();
  });

  tearDown(() async {
    await clearCommonNativeMocks();
  });

  testWidgets('View menu includes Show Action Bar', (tester) async {
    final settings = SettingsController(nativeBridge: NativeBridge.instance);
    final controller = KeyboardShortcutsController(
      settings: settings,
      onToggleRecording: () {},
      onRefreshDevices: () {},
      onToggleActionBar: () async {},
      onCycleOverlayMode: () async {},
      onExportVideo: () async {},
      onShowActionBar: () async {},
      onOpenSettings: () {},
    );

    late List<PlatformMenu> menus;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            menus = controller.buildMenus(context);
            return const SizedBox();
          },
        ),
      ),
    );

    final viewMenu = menus.firstWhere((menu) => menu.label == 'View');
    final showActionBarItem = viewMenu.menus
        .whereType<PlatformMenuItem>()
        .firstWhere((item) => item.label == 'Show Action Bar');

    expect(showActionBarItem.label, 'Show Action Bar');
  });

  testWidgets('Show Action Bar menu item invokes callback once', (
    tester,
  ) async {
    final settings = SettingsController(nativeBridge: NativeBridge.instance);
    var calls = 0;
    final controller = KeyboardShortcutsController(
      settings: settings,
      onToggleRecording: () {},
      onRefreshDevices: () {},
      onToggleActionBar: () async {},
      onCycleOverlayMode: () async {},
      onExportVideo: () async {},
      onShowActionBar: () async {
        calls += 1;
      },
      onOpenSettings: () {},
    );

    late List<PlatformMenu> menus;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            menus = controller.buildMenus(context);
            return const SizedBox();
          },
        ),
      ),
    );

    final viewMenu = menus.firstWhere((menu) => menu.label == 'View');
    final showActionBarItem = viewMenu.menus
        .whereType<PlatformMenuItem>()
        .firstWhere((item) => item.label == 'Show Action Bar');

    showActionBarItem.onSelected?.call();
    await tester.pump();

    expect(calls, 1);
  });

  test('shortcuts include default toggle action bar binding', () {
    final settings = SettingsController(nativeBridge: NativeBridge.instance);
    final controller = KeyboardShortcutsController(
      settings: settings,
      onToggleRecording: () {},
      onRefreshDevices: () {},
      onToggleActionBar: () async {},
      onCycleOverlayMode: () async {},
      onExportVideo: () async {},
      onShowActionBar: () async {},
      onOpenSettings: () {},
    );

    final activator =
        settings.shortcuts.shortcutConfig.bindings[AppShortcutAction
                .toggleActionBar]!
            as SingleActivator;

    expect(controller.shortcuts[activator], isA<ToggleActionBarIntent>());
    expect(activator.trigger, LogicalKeyboardKey.keyB);
    expect(activator.meta, isTrue);
    expect(activator.shift, isTrue);
  });

  testWidgets('toggle action bar shortcut intent invokes callback once', (
    tester,
  ) async {
    final settings = SettingsController(nativeBridge: NativeBridge.instance);
    var calls = 0;
    final controller = KeyboardShortcutsController(
      settings: settings,
      onToggleRecording: () {},
      onRefreshDevices: () {},
      onToggleActionBar: () async {
        calls += 1;
      },
      onCycleOverlayMode: () async {},
      onExportVideo: () async {},
      onShowActionBar: () async {},
      onOpenSettings: () {},
    );

    late Map<Type, Action<Intent>> actions;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            actions = controller.buildActions(context);
            return const SizedBox();
          },
        ),
      ),
    );

    final action =
        actions[ToggleActionBarIntent] as CallbackAction<ToggleActionBarIntent>;
    action.invoke(const ToggleActionBarIntent());
    await tester.pump();

    expect(calls, 1);
  });
}
