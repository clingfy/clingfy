import 'package:clingfy/l10n/app_localizations.dart';
import 'package:clingfy/ui/platform/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

class ExportCancelDialog {
  static Future<bool> show(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    return AppDialog.confirm(
      context,
      title: l10n.cancelExport,
      message: l10n.cancelExportConfirm,
      cancelLabel: l10n.stopExport,
      confirmLabel: l10n.keepExporting,
      primaryResult: false,
      secondaryResult: true
    );
  }
}
