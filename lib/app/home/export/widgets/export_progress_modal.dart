import 'package:flutter/material.dart';

import 'package:clingfy/l10n/app_localizations.dart';
import 'package:clingfy/ui/platform/widgets/app_button.dart';

class ExportProgressModal extends StatelessWidget {
  const ExportProgressModal({
    super.key,
    required this.progress,
    required this.cancelRequested,
    required this.onRunInBackground,
    required this.onCancel,
  });

  final double? progress;
  final bool cancelRequested;
  final VoidCallback onRunInBackground;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Positioned.fill(
      child: Stack(
        children: [
          ModalBarrier(
            dismissible: false,
            color: theme.colorScheme.scrim.withValues(alpha: 0.58),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.exporting,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        cancelRequested
                            ? l10n.cancelingExport
                            : _progressLabel(l10n, progress),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          AppButton(
                            label: l10n.stopExport,
                            onPressed: cancelRequested ? null : onCancel,
                            variant: AppButtonVariant.secondary,
                          ),
                          AppButton(
                            label: l10n.runInBackground,
                            onPressed: onRunInBackground,
                            variant: AppButtonVariant.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _progressLabel(AppLocalizations l10n, double? progress) {
    if (progress == null) return l10n.exporting;
    final pct = (progress.clamp(0.0, 1.0) * 100).round();
    return '${l10n.exporting} $pct%';
  }
}
