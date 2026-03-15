import 'package:clingfy/ui/platform/platform_kind.dart';
import 'package:clingfy/ui/platform/widgets/app_control_box.dart';
import 'package:clingfy/ui/platform/widgets/app_sidebar_tokens.dart';
import 'package:clingfy/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

/// Cross-platform text field wrapper.
///
/// - macOS: `MacosTextField`
/// - fallback: Material `TextFormField`
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.placeholder,
    this.keyboardType,
    this.onSubmitted,
    this.onChanged,
    this.minWidth = AppSidebarTokens.controlMinWidth,
    this.maxWidth = AppSidebarTokens.controlMaxWidth,
    this.expand = false,
    this.heightMac = AppSidebarTokens.controlHeightMac,
    this.heightWin = AppSidebarTokens.controlHeightDefault,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? placeholder;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final double minWidth;
  final double maxWidth;
  final bool expand;
  final double heightMac;
  final double heightWin;

  @override
  Widget build(BuildContext context) {
    final mac = isMac();
    final spacing = context.appSpacing;
    if (mac) {
      return AppControlBox(
        minWidth: minWidth,
        maxWidth: maxWidth,
        expand: expand,
        height: heightMac,
        child: MacosTextField(
          controller: controller,
          enabled: enabled,
          placeholder: placeholder,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
        ),
      );
    }

    return AppControlBox(
      minWidth: minWidth,
      maxWidth: maxWidth,
      expand: expand,
      height: mac ? heightMac : heightWin,
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
        ).copyWith(hintText: placeholder),
        keyboardType: keyboardType,
        onFieldSubmitted: onSubmitted,
        onChanged: onChanged,
      ),
    );
  }
}
