import 'package:clingfy/ui/platform/widgets/app_sidebar_tokens.dart';
import 'package:clingfy/ui/platform/widgets/app_button.dart';
import 'package:clingfy/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

enum AppInlineNoticeVariant { info, success, warning, error }

class AppInlineNotice extends StatelessWidget {
  const AppInlineNotice({
    super.key,
    required this.message,
    this.icon,
    this.variant = AppInlineNoticeVariant.info,
    this.actionLabel,
    this.onActionPressed,
  });

  final String message;
  final IconData? icon;
  final AppInlineNoticeVariant variant;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.appSpacing;
    final tokens = theme.appTokens;
    final (AppToneColors colors, IconData resolvedIcon) = switch (variant) {
      AppInlineNoticeVariant.info => (tokens.noticeInfo, Icons.info_outline),
      AppInlineNoticeVariant.success => (
        tokens.noticeSuccess,
        Icons.check_circle_outline,
      ),
      AppInlineNoticeVariant.warning => (
        tokens.noticeWarning,
        Icons.warning_amber_rounded,
      ),
      AppInlineNoticeVariant.error => (tokens.noticeError, Icons.error_outline),
    };
    final textStyle =
        (variant == AppInlineNoticeVariant.warning ||
                    variant == AppInlineNoticeVariant.error
                ? AppSidebarTokens.warningStyle(theme)
                : AppSidebarTokens.helperStyle(theme))
            .copyWith(color: colors.foreground);

    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border ?? colors.foreground.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? resolvedIcon, size: 14, color: colors.foreground),
          SizedBox(width: spacing.sm - 2),
          Expanded(child: Text(message, style: textStyle)),
          if (actionLabel != null && onActionPressed != null) ...[
            SizedBox(width: spacing.sm),
            AppButton(
              label: actionLabel!,
              onPressed: onActionPressed,
              size: AppButtonSize.compact,
              variant: AppButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }
}
