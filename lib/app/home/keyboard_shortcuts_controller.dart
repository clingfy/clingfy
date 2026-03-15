import 'package:flutter/material.dart';
import 'package:clingfy/l10n/app_localizations.dart';
import 'package:clingfy/app/settings/shortcuts/shortcut_config.dart';
import 'package:clingfy/app/settings/settings_controller.dart';

class KeyboardShortcutsController {
  final SettingsController settings;

  final VoidCallback onToggleRecording;
  final VoidCallback onRefreshDevices;
  final Future<void> Function() onToggleActionBar;
  final Future<void> Function() onCycleOverlayMode;
  final Future<void> Function() onExportVideo;
  final Future<void> Function() onShowActionBar;
  final VoidCallback onOpenSettings;

  KeyboardShortcutsController({
    required this.settings,
    required this.onToggleRecording,
    required this.onRefreshDevices,
    required this.onToggleActionBar,
    required this.onCycleOverlayMode,
    required this.onExportVideo,
    required this.onShowActionBar,
    required this.onOpenSettings,
  });

  Map<ShortcutActivator, Intent> get shortcuts {
    final bindings = settings.shortcuts.shortcutConfig.bindings;
    return {
      bindings[AppShortcutAction.toggleRecording]!: const ActivateIntent(),
      bindings[AppShortcutAction.refreshDevices]!: const RefreshIntent(),
      bindings[AppShortcutAction.toggleActionBar]!:
          const ToggleActionBarIntent(),
      bindings[AppShortcutAction.cycleOverlayMode]!: const CycleOverlayIntent(),
      bindings[AppShortcutAction.exportVideo]!: const ExportIntent(),
      bindings[AppShortcutAction.openSettings]!: const OpenSettingsIntent(),
    };
  }

  Map<Type, Action<Intent>> buildActions(BuildContext context) {
    return {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          onToggleRecording();
          return null;
        },
      ),
      RefreshIntent: CallbackAction<RefreshIntent>(
        onInvoke: (_) {
          onRefreshDevices();
          return null;
        },
      ),
      ToggleActionBarIntent: CallbackAction<ToggleActionBarIntent>(
        onInvoke: (_) async {
          await onToggleActionBar();
          return null;
        },
      ),
      CycleOverlayIntent: CallbackAction<CycleOverlayIntent>(
        onInvoke: (_) async {
          await onCycleOverlayMode();
          return null;
        },
      ),
      ExportIntent: CallbackAction<ExportIntent>(
        onInvoke: (_) async {
          await onExportVideo();
          return null;
        },
      ),
      OpenSettingsIntent: CallbackAction<OpenSettingsIntent>(
        onInvoke: (_) {
          onOpenSettings();
          return null;
        },
      ),
    };
  }

  List<PlatformMenu> buildMenus(BuildContext context) {
    final bindings = settings.shortcuts.shortcutConfig.bindings;
    final appMenuGroups = <PlatformMenuItem>[
      PlatformMenuItemGroup(
        members: [
          PlatformMenuItem(
            label: AppLocalizations.of(context)!.aboutClingfy,
            onSelected: () {
              showAboutDialog(
                context: context,
                applicationName: AppLocalizations.of(context)!.appTitle,
                applicationVersion: '1.0.0',
              );
            },
          ),
        ],
      ),
    ];

    if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.quit)) {
      appMenuGroups.add(
        const PlatformMenuItemGroup(
          members: [
            PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
          ],
        ),
      );
    }

    return [
      PlatformMenu(
        label: AppLocalizations.of(context)!.appTitle,
        menus: appMenuGroups,
      ),
      PlatformMenu(
        label: AppLocalizations.of(context)!.menuFile,
        menus: [
          PlatformMenuItem(
            label: AppLocalizations.of(context)!.exportVideo,
            shortcut: bindings[AppShortcutAction.exportVideo] is SingleActivator
                ? bindings[AppShortcutAction.exportVideo] as SingleActivator
                : null,
            onSelected: () {
              onExportVideo();
            },
          ),
          PlatformMenuItem(
            label: AppLocalizations.of(context)!.openSettings,
            shortcut:
                bindings[AppShortcutAction.openSettings] is SingleActivator
                ? bindings[AppShortcutAction.openSettings] as SingleActivator
                : null,
            onSelected: () {
              onOpenSettings();
            },
          ),
        ],
      ),
      PlatformMenu(
        label: AppLocalizations.of(context)!.menuView,
        menus: [
          PlatformMenuItem(
            label: AppLocalizations.of(context)!.refreshDevices,
            shortcut:
                bindings[AppShortcutAction.refreshDevices] is SingleActivator
                ? bindings[AppShortcutAction.refreshDevices] as SingleActivator
                : null,
            onSelected: () {
              onRefreshDevices();
            },
          ),
          PlatformMenuItem(
            label: AppLocalizations.of(context)!.showActionBar,
            onSelected: () {
              onShowActionBar();
            },
          ),
          PlatformMenuItem(
            label: AppLocalizations.of(context)!.cycleOverlayMode,
            shortcut:
                bindings[AppShortcutAction.cycleOverlayMode] is SingleActivator
                ? bindings[AppShortcutAction.cycleOverlayMode]
                      as SingleActivator
                : null,
            onSelected: () {
              onCycleOverlayMode();
            },
          ),
        ],
      ),
      PlatformMenu(
        label: AppLocalizations.of(context)!.menuRecord,
        menus: [
          PlatformMenuItem(
            label: AppLocalizations.of(context)!.toggleRecording,
            shortcut:
                bindings[AppShortcutAction.toggleRecording] is SingleActivator
                ? bindings[AppShortcutAction.toggleRecording] as SingleActivator
                : null,
            onSelected: () {
              onToggleRecording();
            },
          ),
        ],
      ),
    ];
  }
}

class RefreshIntent extends Intent {
  const RefreshIntent();
}

class ToggleActionBarIntent extends Intent {
  const ToggleActionBarIntent();
}

class CycleOverlayIntent extends Intent {
  const CycleOverlayIntent();
}

class ExportIntent extends Intent {
  const ExportIntent();
}

class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}
