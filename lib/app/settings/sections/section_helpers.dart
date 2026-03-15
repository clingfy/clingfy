import 'package:clingfy/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

Widget buildSectionPage(
  BuildContext context, {
  required List<Widget> children,
}) {
  return ListView(
    padding: const EdgeInsets.all(16),
    children: [...children, const SizedBox(height: 24)],
  );
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.appTokens.panelBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [Expanded(child: child)],
            ),
          ],
        ),
      ),
    );
  }
}
