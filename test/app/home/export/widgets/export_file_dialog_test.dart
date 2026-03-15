import 'package:clingfy/app/home/export/widgets/export_file_dialog.dart';
import 'package:clingfy/core/export/models/export_settings_types.dart';
import 'package:clingfy/core/models/app_models.dart';
import 'package:clingfy/l10n/app_localizations.dart';
import 'package:clingfy/ui/platform/widgets/app_icon_button.dart';
import 'package:clingfy/ui/platform/widgets/platform_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildDialog({ExportFormat initialExportFormat = ExportFormat.mov}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MacosTheme(
        data: MacosThemeData.light(),
        child: Scaffold(
          body: ExportFileDialog(
            initialFileName: 'Clingfy Export',
            initialDirectory: '/tmp',
            initialResolutionPreset: ResolutionPreset.auto,
            initialExportFormat: initialExportFormat,
            initialExportCodec: ExportCodec.hevc,
            initialExportBitrate: ExportBitratePreset.auto,
            onPickFolder: () async => null,
          ),
        ),
      ),
    );
  }

  testWidgets('format dropdown includes mov gif and mp4', (tester) async {
    await tester.pumpWidget(buildDialog());
    await tester.pumpAndSettle();

    final formatDropdown = tester.widget<PlatformDropdown<ExportFormat>>(
      find.byWidgetPredicate(
        (widget) => widget is PlatformDropdown<ExportFormat>,
      ),
    );

    expect(formatDropdown.items.map((item) => item.label).toList(), [
      '.mov',
      '.gif',
      '.mp4',
    ]);
  });

  testWidgets('gif format hides codec and bitrate controls', (tester) async {
    await tester.pumpWidget(buildDialog(initialExportFormat: ExportFormat.gif));
    await tester.pumpAndSettle();

    expect(find.text('Codec'), findsNothing);
    expect(find.text('Bitrate'), findsNothing);
  });

  testWidgets('switching format to gif hides codec and bitrate controls', (
    tester,
  ) async {
    await tester.pumpWidget(buildDialog(initialExportFormat: ExportFormat.mov));
    await tester.pumpAndSettle();

    expect(find.text('Codec'), findsOneWidget);
    expect(find.text('Bitrate'), findsOneWidget);

    final formatDropdown = tester.widget<PlatformDropdown<ExportFormat>>(
      find.byWidgetPredicate(
        (widget) => widget is PlatformDropdown<ExportFormat>,
      ),
    );
    formatDropdown.onChanged?.call(ExportFormat.gif);
    await tester.pumpAndSettle();

    expect(find.text('Codec'), findsNothing);
    expect(find.text('Bitrate'), findsNothing);
  });

  testWidgets('uses close icon in header instead of footer cancel button', (
    tester,
  ) async {
    await tester.pumpWidget(buildDialog());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('export_file_dialog_close_button')),
      findsOneWidget,
    );
    expect(find.byType(AppIconButton), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Export'), findsOneWidget);
  });
}
