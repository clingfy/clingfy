import 'package:clingfy/core/permissions/models/recording_start_preflight.dart';
import 'package:clingfy/l10n/app_localizations.dart';
import 'package:clingfy/ui/platform/widgets/app_button.dart';
import 'package:clingfy/ui/platform/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

enum StartRecordingPermissionDecision {
  grantPermissions,
  recordWithoutMissingOptionalFeatures,
  cancel,
}

class StartRecordingPermissionDialog {
  static Future<StartRecordingPermissionDecision?> show(
    BuildContext context, {
    required RecordingStartPreflight preflight,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final hasHardBlocker = preflight.hasHardBlocker;

    return AppDialog.show<StartRecordingPermissionDecision>(
      context,
      title: l10n.recordingSetupNeedsAttention,
      barrierDismissible: false,
      primaryLabel: l10n.grantPermissions,
      secondaryLabel: hasHardBlocker
          ? l10n.cancel
          : l10n.recordWithoutMissingFeatures,
      primaryResult: StartRecordingPermissionDecision.grantPermissions,
      secondaryResult: hasHardBlocker
          ? StartRecordingPermissionDecision.cancel
          : StartRecordingPermissionDecision
                .recordWithoutMissingOptionalFeatures,
      content: Builder(
        builder: (dialogContext) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (preflight.missingHard.isNotEmpty) ...[
                Text(
                  l10n.missingRequiredPermission,
                  style: Theme.of(
                    dialogContext,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...preflight.missingHard.map(
                  (kind) =>
                      _PermissionBullet(label: _labelFor(dialogContext, kind)),
                ),
              ],
              if (preflight.missingHard.isNotEmpty &&
                  preflight.missingOptional.isNotEmpty)
                const SizedBox(height: 16),
              if (preflight.missingOptional.isNotEmpty) ...[
                Text(
                  l10n.missingOptionalPermissionsForRequestedFeatures,
                  style: Theme.of(
                    dialogContext,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...preflight.missingOptional.map(
                  (kind) =>
                      _PermissionBullet(label: _labelFor(dialogContext, kind)),
                ),
              ],
              if (!hasHardBlocker) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    onPressed: () {
                      Navigator.of(
                        dialogContext,
                      ).pop(StartRecordingPermissionDecision.cancel);
                    },
                    label: l10n.cancel,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.compact,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static String _labelFor(BuildContext context, MissingPermissionKind kind) {
    final l10n = AppLocalizations.of(context)!;
    switch (kind) {
      case MissingPermissionKind.screenRecording:
        return l10n.permissionsScreenRecording;
      case MissingPermissionKind.microphone:
        return l10n.microphoneForVoice;
      case MissingPermissionKind.camera:
        return l10n.cameraForFaceCam;
      case MissingPermissionKind.accessibility:
        return l10n.accessibilityForCursorHighlight;
    }
  }
}

class _PermissionBullet extends StatelessWidget {
  const _PermissionBullet({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
