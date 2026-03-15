import 'package:clingfy/ui/platform/widgets/app_sidebar_tokens.dart';
import 'package:flutter/material.dart';

/// Standard row for slider-based sidebar settings.
class AppSliderRow extends StatelessWidget {
  const AppSliderRow({
    super.key,
    required this.label,
    required this.slider,
    this.valueText,
    this.helperText,
  });

  final String label;
  final String? valueText;
  final String? helperText;
  final Widget slider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = AppSidebarTokens.rowTitleStyle(theme);
    final valueStyle = AppSidebarTokens.valueStyle(theme);
    final helperStyle = AppSidebarTokens.helperStyle(theme);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(label, style: labelStyle)),
              if (valueText != null) ...[
                const SizedBox(width: AppSidebarTokens.controlGap),
                Text(valueText!, style: valueStyle),
              ],
            ],
          ),
          if (helperText != null) ...[
            const SizedBox(height: AppSidebarTokens.compactGap / 2),
            Text(helperText!, style: helperStyle),
          ],
          const SizedBox(height: AppSidebarTokens.compactGap),
          slider,
        ],
      ),
    );
  }
}
