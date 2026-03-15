import 'package:clingfy/ui/platform/platform_kind.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart' as macos;

class PlatformCheckbox extends StatelessWidget {
  const PlatformCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (isMac() && macos.MacosTheme.maybeOf(context) != null) {
      return macos.MacosCheckbox(
        value: value,
        onChanged: onChanged == null ? null : (next) => onChanged!(next),
        semanticLabel: semanticLabel,
        activeColor: Theme.of(context).primaryColor,
      );
    }

    if (isWindows()) {
      return fluent.Checkbox(
        checked: value,
        onChanged: onChanged,
        semanticLabel: semanticLabel,
      );
    }

    return Checkbox(value: value, onChanged: onChanged);
  }
}
