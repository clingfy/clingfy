import 'package:flutter/material.dart';
import 'package:clingfy/ui/theme/app_theme.dart';

/// Shared design tokens for desktop sidebars.
///
/// These values intentionally keep spacing and typography compact so complex
/// settings panels feel native and readable on desktop.
abstract final class AppSidebarTokens {
  static const double sectionGap = 24;
  static const double rowGap = 12;
  static const double compactGap = 8;
  static const double compactRowGap = 4;
  static const double controlGap = 12;
  static const double contentHorizontalPadding = 20;
  static const double headerTopPadding = 24;
  static const double headerBottomPadding = 12;
  static const double railWidth = 60;
  static const double railItemGap = 24;
  static const double railItemVerticalPadding = 16;

  static const double labelWidth = 170;
  static const double stackBreakpoint = 520;

  static const double controlMinWidth = 220;
  static const double controlMaxWidth = 360;
  static const double controlHeightMac = 30;
  static const double controlHeightDefault = 36;
  static const double compactButtonHeight = 32;

  static TextStyle rowTitleStyle(ThemeData theme) {
    return theme.appTypography.rowLabel.copyWith(
      color: theme.colorScheme.onSurface,
    );
  }

  static TextStyle helperStyle(ThemeData theme) {
    return theme.appTypography.bodyMuted.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  static TextStyle valueStyle(ThemeData theme) {
    return theme.appTypography.value.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  static TextStyle sectionHeaderStyle(ThemeData theme) {
    return theme.appTypography.sectionEyebrow.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  static TextStyle railLabelStyle(ThemeData theme, {required bool selected}) {
    return theme.appTypography.caption.copyWith(
      color: selected
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
  }

  static TextStyle warningStyle(ThemeData theme) {
    return theme.appTypography.bodyMuted.copyWith(
      color: theme.colorScheme.error,
      fontWeight: FontWeight.w500,
    );
  }
}
