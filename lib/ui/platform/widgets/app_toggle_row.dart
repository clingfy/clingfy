import 'package:clingfy/ui/platform/widgets/app_sidebar_tokens.dart';
import 'package:clingfy/ui/platform/widgets/platform_switch.dart';
import 'package:flutter/material.dart';

/// Standard row for boolean sidebar settings.
class AppToggleRow extends StatelessWidget {
  const AppToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = AppSidebarTokens.rowTitleStyle(theme);
    final subtitleStyle = AppSidebarTokens.helperStyle(
      theme,
    ).copyWith(color: theme.colorScheme.secondary);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: subtitle == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSidebarTokens.compactGap / 2),
                  Text(subtitle!, style: subtitleStyle),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSidebarTokens.controlGap),
          Padding(
            padding: EdgeInsets.only(top: subtitle == null ? 0 : 2),
            child: PlatformSwitch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}
