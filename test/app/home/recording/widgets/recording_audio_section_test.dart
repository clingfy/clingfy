import 'package:clingfy/app/home/recording/widgets/recording_audio_section.dart';
import 'package:clingfy/core/models/app_models.dart';
import 'package:clingfy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _monitorPrefsKey = 'pref.recordingMicMonitorVisibility';

Widget _buildSection({
  required String selectedAudioSourceId,
  bool loadingAudio = false,
  bool systemAudioEnabled = false,
  bool excludeMicFromSystemAudio = false,
  double micInputLevelLinear = 0.0,
  double micInputLevelDbfs = -160.0,
  bool micInputTooLow = false,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MacosTheme(
      data: MacosThemeData.light(),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 720,
            child: RecordingAudioSection(
              isRecording: false,
              audioSources: const [
                AudioSource(id: 'mic-1', name: 'Built-in Microphone'),
              ],
              selectedAudioSourceId: selectedAudioSourceId,
              loadingAudio: loadingAudio,
              systemAudioEnabled: systemAudioEnabled,
              excludeMicFromSystemAudio: excludeMicFromSystemAudio,
              micInputLevelLinear: micInputLevelLinear,
              micInputLevelDbfs: micInputLevelDbfs,
              micInputTooLow: micInputTooLow,
              onAudioSourceChanged: (_) {},
              onRefreshAudio: () {},
              onSystemAudioEnabledChanged: (_) {},
              onExcludeMicFromSystemAudioChanged: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required String selectedAudioSourceId,
  Map<String, Object> initialPrefs = const {},
  bool loadingAudio = false,
  bool systemAudioEnabled = false,
  bool excludeMicFromSystemAudio = false,
  double micInputLevelLinear = 0.0,
  double micInputLevelDbfs = -160.0,
  bool micInputTooLow = false,
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  await tester.pumpWidget(
    _buildSection(
      selectedAudioSourceId: selectedAudioSourceId,
      loadingAudio: loadingAudio,
      systemAudioEnabled: systemAudioEnabled,
      excludeMicFromSystemAudio: excludeMicFromSystemAudio,
      micInputLevelLinear: micInputLevelLinear,
      micInputLevelDbfs: micInputLevelDbfs,
      micInputTooLow: micInputTooLow,
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

AppLocalizations _l10n(WidgetTester tester) {
  return AppLocalizations.of(
    tester.element(find.byType(RecordingAudioSection)),
  )!;
}

void main() {
  testWidgets('no mic selected hides the monitor', (tester) async {
    await _pumpSection(tester, selectedAudioSourceId: '__none__');

    final l10n = _l10n(tester);

    expect(find.byKey(const Key('mic_input_monitor_compact')), findsNothing);
    expect(find.byKey(const Key('mic_input_monitor_expanded')), findsNothing);
    expect(find.text(l10n.inputDevice), findsOneWidget);
    expect(find.text(l10n.recordingSystemAudio), findsOneWidget);
  });

  testWidgets('mic selected shows compact monitor by default', (tester) async {
    await _pumpSection(
      tester,
      selectedAudioSourceId: 'mic-1',
      micInputLevelLinear: 0.42,
      micInputLevelDbfs: -23.1,
    );

    final compact = find.byKey(const Key('mic_input_monitor_compact'));
    expect(compact, findsOneWidget);
    expect(find.byKey(const Key('mic_input_monitor_expanded')), findsNothing);
    expect(find.text('-23.1 dBFS'), findsOneWidget);
    expect(tester.getSize(compact).height, 40);
  });

  testWidgets('persisted expanded preference restores expanded state', (
    tester,
  ) async {
    await _pumpSection(
      tester,
      selectedAudioSourceId: 'mic-1',
      initialPrefs: const {_monitorPrefsKey: 'expanded'},
      micInputLevelLinear: 0.42,
      micInputLevelDbfs: -23.1,
    );

    expect(find.byKey(const Key('mic_input_monitor_expanded')), findsOneWidget);
    expect(find.byKey(const Key('mic_input_monitor_compact')), findsNothing);
  });

  testWidgets('tapping compact monitor expands and persists preference', (
    tester,
  ) async {
    await _pumpSection(
      tester,
      selectedAudioSourceId: 'mic-1',
      micInputLevelLinear: 0.35,
      micInputLevelDbfs: -24.0,
    );

    await tester.tap(find.byKey(const Key('mic_input_monitor_compact')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();

    expect(find.byKey(const Key('mic_input_monitor_expanded')), findsOneWidget);
    expect(prefs.getString(_monitorPrefsKey), 'expanded');
  });

  testWidgets('tapping expanded chevron collapses and persists preference', (
    tester,
  ) async {
    await _pumpSection(
      tester,
      selectedAudioSourceId: 'mic-1',
      initialPrefs: const {_monitorPrefsKey: 'expanded'},
      micInputLevelLinear: 0.35,
      micInputLevelDbfs: -24.0,
    );

    await tester.tap(find.byKey(const Key('mic_input_monitor_toggle')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();

    expect(find.byKey(const Key('mic_input_monitor_compact')), findsOneWidget);
    expect(find.byKey(const Key('mic_input_monitor_expanded')), findsNothing);
    expect(prefs.getString(_monitorPrefsKey), 'compact');
  });

  testWidgets('compact low-input state keeps warning visible', (tester) async {
    await _pumpSection(
      tester,
      selectedAudioSourceId: 'mic-1',
      micInputLevelLinear: 0.08,
      micInputLevelDbfs: -45.2,
      micInputTooLow: true,
    );

    final l10n = _l10n(tester);

    expect(find.byKey(const Key('mic_input_monitor_compact')), findsOneWidget);
    expect(find.byKey(const Key('mic_input_monitor_badge')), findsOneWidget);
    expect(find.text(l10n.micInputMonitorLowBadge), findsOneWidget);
    expect(find.text(l10n.micInputMonitorLowHint), findsNothing);
    expect(find.text(l10n.micInputTooLowWarning), findsNothing);
  });

  testWidgets('expanded mode shows richer monitoring detail', (tester) async {
    await _pumpSection(
      tester,
      selectedAudioSourceId: 'mic-1',
      initialPrefs: const {_monitorPrefsKey: 'expanded'},
      micInputLevelLinear: 0.08,
      micInputLevelDbfs: -45.2,
      micInputTooLow: true,
    );

    final l10n = _l10n(tester);

    expect(find.byKey(const Key('mic_input_monitor_expanded')), findsOneWidget);
    expect(find.text(l10n.micInputMonitorTitle), findsOneWidget);
    expect(find.text(l10n.micInputMonitorLowBadge), findsOneWidget);
    expect(find.text(l10n.micInputMonitorLowHint), findsOneWidget);
  });

  testWidgets('no mic selected does not overwrite stored preference', (
    tester,
  ) async {
    await _pumpSection(
      tester,
      selectedAudioSourceId: '__none__',
      initialPrefs: const {_monitorPrefsKey: 'expanded'},
    );

    final prefs = await SharedPreferences.getInstance();

    expect(find.byKey(const Key('mic_input_monitor_compact')), findsNothing);
    expect(find.byKey(const Key('mic_input_monitor_expanded')), findsNothing);
    expect(prefs.getString(_monitorPrefsKey), 'expanded');
  });

  testWidgets('existing controls still render and follow current rules', (
    tester,
  ) async {
    await _pumpSection(
      tester,
      selectedAudioSourceId: '__none__',
      systemAudioEnabled: true,
    );

    final l10n = _l10n(tester);

    expect(find.text(l10n.inputDevice), findsOneWidget);
    expect(find.text(l10n.recordingSystemAudio), findsOneWidget);
    expect(find.text(l10n.recordingExcludeMicFromSystemAudio), findsNothing);

    await _pumpSection(
      tester,
      selectedAudioSourceId: 'mic-1',
      systemAudioEnabled: true,
    );

    expect(find.text(l10n.recordingExcludeMicFromSystemAudio), findsOneWidget);
  });
}
