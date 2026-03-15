import 'package:clingfy/l10n/app_localizations.dart';
import 'package:clingfy/ui/platform/widgets/app_dialog.dart';
import 'package:clingfy/ui/platform/widgets/platform_checkbox.dart';
import 'package:flutter/material.dart';

class CloseUnexportedRecordingDialogResult {
  const CloseUnexportedRecordingDialogResult({
    required this.confirmed,
    required this.doNotShowAgain,
  });

  final bool confirmed;
  final bool doNotShowAgain;
}

class CloseUnexportedRecordingDialog {
  static Future<CloseUnexportedRecordingDialogResult?> show(
    BuildContext context,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    var doNotShowAgain = false;

    return AppDialog.show<CloseUnexportedRecordingDialogResult>(
      context,
      title: l10n.closeUnexportedRecordingTitle,
      barrierDismissible: false,
      primaryLabel: l10n.cancel,

      secondaryLabel: l10n.close,
      secondaryBuilder:  () => CloseUnexportedRecordingDialogResult(
        confirmed: true,
        doNotShowAgain: doNotShowAgain,
      ),
      secondaryResult: const CloseUnexportedRecordingDialogResult(
        confirmed: false,
        doNotShowAgain: false,
      ),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.closeUnexportedRecordingMessage),
              const SizedBox(height: 16),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    setState(() => doNotShowAgain = !doNotShowAgain);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlatformCheckbox(
                          value: doNotShowAgain,
                          onChanged: (value) {
                            setState(() => doNotShowAgain = value ?? false);
                          },
                        ),
                        const SizedBox(width: 8),
                        Flexible(child: Text(l10n.doNotShowAgain)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<bool> confirmCloseUnexportedRecordingIfNeeded(
  BuildContext context, {
  required bool warningEnabled,
  required bool hasExportedCurrentRecording,
  required Future<void> Function() disableFutureWarnings,
}) async {
  if (!warningEnabled || hasExportedCurrentRecording) {
    return true;
  }

  final result = await CloseUnexportedRecordingDialog.show(context);
  if (result == null || !result.confirmed) {
    return false;
  }

  if (result.doNotShowAgain) {
    await disableFutureWarnings();
  }
  return true;
}
