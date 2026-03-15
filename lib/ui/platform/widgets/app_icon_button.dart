import 'package:clingfy/ui/platform/platform_kind.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.size = 18,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (isMac() && MacosTheme.maybeOf(context) != null) {
      final button = MacosIconButton(
        onPressed: onPressed,
        icon: MacosIcon(icon, size: size + 2, color: color),
        semanticLabel: tooltip,
        boxConstraints: const BoxConstraints.tightFor(width: 34, height: 34),
      );

      return tooltip == null
          ? button
          : MacosTooltip(message: tooltip!, child: button);
    }

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: size, color: color),
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      splashRadius: 16,
    );
  }
}
