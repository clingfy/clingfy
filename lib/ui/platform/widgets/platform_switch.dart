import 'package:clingfy/ui/platform/platform_kind.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart' as macos;
import 'package:fluent_ui/fluent_ui.dart' as fluent;

class PlatformSwitch extends StatelessWidget {
  const PlatformSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    if (isMac()) {
      return macos.MacosSwitch(value: value, onChanged: onChanged);
    }

    if (isWindows()) {
      // Fluent has ToggleSwitch; we keep it compact by not providing content.
      return fluent.ToggleSwitch(
        checked: value,
        onChanged: onChanged == null ? null : (v) => onChanged!(v),
        content: const SizedBox.shrink(),
      );
    }

    // Fallback: simple Cupertino switch (works without Material)
    return macos.MacosSwitch(value: value, onChanged: onChanged);
  }
}
