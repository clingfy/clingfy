import 'package:flutter/material.dart';
import 'package:clingfy/ui/theme/app_theme.dart';

class AppSegmentedItem<T> {
  const AppSegmentedItem({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    this.expand = true,
    this.minHeight = 40,
    this.minSegmentWidth = 110,
    this.radius = 10,
    this.scrollWhenOverflow = true,
    this.compact = false,
  });

  final T value;
  final ValueChanged<T>? onChanged;
  final List<AppSegmentedItem<T>> items;

  /// If true, tries to fill available width (equal-sized segments).
  final bool expand;

  final double minHeight;
  final double minSegmentWidth;
  final double radius;

  /// If width is too small for equal segments, allow horizontal scroll.
  final bool scrollWhenOverflow;

  /// Compact density for sidebar-like contexts.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.appSpacing;
    final cs = theme.colorScheme;

    final selectedIndex = items.indexWhere((e) => e.value == value);
    final isSelected = List<bool>.generate(
      items.length,
      (i) => i == selectedIndex,
    );
    final effectiveMinHeight = compact
        ? (minHeight - 4).clamp(32.0, minHeight)
        : minHeight;
    final labelStyle = theme.appTypography.button.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: compact ? 13 : null,
      height: compact ? 1.2 : null,
    );
    final iconSize = compact ? 15.0 : 16.0;
    final horizontalPadding = compact ? spacing.sm : spacing.md - 2;
    final iconGap = compact ? spacing.xs + 1 : spacing.sm - 2;

    Widget buildToggle({required double minSegWidth, double? maxSegWidth}) {
      return ToggleButtons(
        isSelected: isSelected,
        onPressed: onChanged == null ? null : (i) => onChanged!(items[i].value),
        borderRadius: BorderRadius.circular(radius),
        constraints: BoxConstraints(
          minHeight: effectiveMinHeight,
          minWidth: minSegWidth,
          maxWidth: maxSegWidth ?? double.infinity,
        ),
        borderColor: cs.outlineVariant.withValues(alpha: 0.7),
        selectedBorderColor: cs.primary.withValues(alpha: 0.9),
        fillColor: cs.primary.withValues(alpha: 0.14),
        selectedColor: cs.primary,
        color: cs.onSurfaceVariant,
        textStyle: labelStyle,
        children: [
          for (final it in items)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (it.icon != null) ...[
                    Icon(it.icon, size: iconSize),
                    SizedBox(width: iconGap),
                  ],
                  Flexible(
                    child: Text(
                      it.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final maxW = c.maxWidth.isFinite ? c.maxWidth : 0.0;

        // If not expanding, just use intrinsic-ish segment width.
        if (!expand || maxW <= 0) {
          return buildToggle(minSegWidth: minSegmentWidth);
        }

        // Border-aware width budget to avoid subtle pixel overflows.
        final borderBudgetPx = (items.length + 1).toDouble();
        final segW = ((maxW - borderBudgetPx) / items.length).floorToDouble();
        final canFit = segW >= minSegmentWidth;

        if (!canFit && scrollWhenOverflow) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: buildToggle(minSegWidth: minSegmentWidth),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: buildToggle(minSegWidth: segW, maxSegWidth: segW),
        );
      },
    );
  }
}
