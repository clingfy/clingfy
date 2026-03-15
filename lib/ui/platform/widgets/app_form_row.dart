import 'package:clingfy/ui/platform/widgets/app_sidebar_tokens.dart';
import 'package:clingfy/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Desktop-style settings row: label on the left, control on the right.
///
/// If the available width is small, it stacks into a column (label above control).
class AppFormRow extends StatelessWidget {
  const AppFormRow({
    super.key,
    required this.control,
    this.label,
    this.helper,
    this.labelWidth = AppSidebarTokens.labelWidth,
    this.stackBreakpoint = AppSidebarTokens.stackBreakpoint,
    this.gap = AppSidebarTokens.controlGap,
  });

  final String? label;
  final String? helper;
  final Widget control;

  /// Fixed width of the label column when not stacked.
  final double labelWidth;

  /// Below this width, the row becomes a column.
  final double stackBreakpoint;

  /// Horizontal spacing between label and control when not stacked.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.appSpacing;
    final labelStyle = AppSidebarTokens.rowTitleStyle(theme);
    final helperStyle = AppSidebarTokens.helperStyle(theme);

    return LayoutBuilder(
      builder: (context, c) {
        final stacked = c.maxWidth < stackBreakpoint;

        // Control-only row.
        if (label == null) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.xs / 2),
            child: Align(
              alignment: stacked ? Alignment.centerLeft : Alignment.centerRight,
              child: control,
            ),
          );
        }

        if (stacked) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.xs / 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label!, style: labelStyle),
                if (helper != null) ...[
                  SizedBox(height: spacing.xs),
                  Text(helper!, style: helperStyle),
                ],
                SizedBox(height: spacing.sm),
                control,
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(vertical: spacing.xs / 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: labelWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label!, style: labelStyle),
                    if (helper != null) ...[
                      SizedBox(height: spacing.xs),
                      Text(helper!, style: helperStyle),
                    ],
                  ],
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: Align(alignment: Alignment.centerRight, child: control),
              ),
            ],
          ),
        );
      },
    );
  }
}
