import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppShortcutAction {
  toggleRecording,
  refreshDevices,
  toggleActionBar,
  cycleOverlayMode,
  exportVideo,
  openSettings,
}

class ShortcutConfig {
  final Map<AppShortcutAction, ShortcutActivator> bindings;

  const ShortcutConfig({required this.bindings});

  static ShortcutConfig get defaults => ShortcutConfig(
    bindings: {
      AppShortcutAction.toggleRecording: const SingleActivator(
        LogicalKeyboardKey.space,
      ),
      AppShortcutAction.refreshDevices: const SingleActivator(
        LogicalKeyboardKey.keyR,
        meta: true,
      ),
      AppShortcutAction.toggleActionBar: const SingleActivator(
        LogicalKeyboardKey.keyB,
        meta: true,
        shift: true,
      ),
      AppShortcutAction.cycleOverlayMode: const SingleActivator(
        LogicalKeyboardKey.keyO,
        meta: true,
        shift: true,
      ),
      AppShortcutAction.exportVideo: const SingleActivator(
        LogicalKeyboardKey.keyE,
        meta: true,
      ),
      AppShortcutAction.openSettings: const SingleActivator(
        LogicalKeyboardKey.comma,
        meta: true,
      ),
    },
  );

  Map<String, dynamic> toJson() {
    return bindings.map((key, value) {
      if (value is SingleActivator) {
        return MapEntry(key.name, {
          'keyId': value.trigger.keyId,
          'keyLabel': value.trigger.keyLabel,
          'control': value.control,
          'shift': value.shift,
          'alt': value.alt,
          'meta': value.meta,
        });
      }
      return MapEntry(key.name, null);
    });
  }

  static ShortcutConfig fromJson(Map<String, dynamic> json) {
    final bindings = <AppShortcutAction, ShortcutActivator>{};

    for (final key in json.keys) {
      final action = AppShortcutAction.values.firstWhere(
        (e) => e.name == key,
        orElse: () => AppShortcutAction.toggleRecording, // Fallback
      );

      final value = json[key];
      if (value is Map<String, dynamic>) {
        final keyId = value['keyId'] as int;
        final trigger =
            LogicalKeyboardKey.findKeyByKeyId(keyId) ??
            LogicalKeyboardKey(keyId);

        bindings[action] = SingleActivator(
          trigger,
          control: value['control'] ?? false,
          shift: value['shift'] ?? false,
          alt: value['alt'] ?? false,
          meta: value['meta'] ?? false,
        );
      }
    }

    // Merge with defaults for any missing keys
    final defaults = ShortcutConfig.defaults.bindings;
    for (final action in AppShortcutAction.values) {
      if (!bindings.containsKey(action) && defaults.containsKey(action)) {
        bindings[action] = defaults[action]!;
      }
    }

    return ShortcutConfig(bindings: bindings);
  }
}
