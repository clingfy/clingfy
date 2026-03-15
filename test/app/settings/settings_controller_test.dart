import 'package:clingfy/core/bridges/native_method_channel.dart';
import 'package:clingfy/core/bridges/native_bridge.dart';
import 'package:clingfy/app/settings/settings_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(NativeChannel.screenRecorder);

  late String? chosenFolder;
  late int openSaveFolderCalls;
  late List<bool> preRecordingBarEnabledValues;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    chosenFolder = null;
    openSaveFolderCalls = 0;
    preRecordingBarEnabledValues = <bool>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'chooseSaveFolder':
              return chosenFolder;
            case 'openSaveFolder':
              openSaveFolderCalls += 1;
              return null;
            case 'setPreRecordingBarEnabled':
              final args = (call.arguments as Map?)?.cast<String, dynamic>();
              preRecordingBarEnabledValues.add(
                (args?['enabled'] as bool?) ?? true,
              );
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('updatePostAudioGainDb notifies listeners', () async {
    final settings = SettingsController(nativeBridge: NativeBridge.instance);
    var calls = 0;
    settings.addListener(() {
      calls++;
    });

    await settings.post.updatePostAudioGainDb(6.0);

    expect(settings.post.postAudioGainDb, 6.0);
    expect(calls, 1);
  });

  test('updatePostAudioVolumePercent notifies listeners', () async {
    final settings = SettingsController(nativeBridge: NativeBridge.instance);
    var calls = 0;
    settings.addListener(() {
      calls++;
    });

    await settings.post.updatePostAudioVolumePercent(72.0);

    expect(settings.post.postAudioVolumePercent, 72.0);
    expect(calls, 1);
  });

  test('updatePostTargetLoudnessDbfs notifies listeners', () async {
    final settings = SettingsController(nativeBridge: NativeBridge.instance);
    var calls = 0;
    settings.addListener(() {
      calls++;
    });

    await settings.post.updatePostTargetLoudnessDbfs(-14.0);

    expect(settings.post.postTargetLoudnessDbfs, -14.0);
    expect(calls, 1);
  });

  test('chooseSaveFolderPath persists the selected folder', () async {
    chosenFolder = '/tmp/Exports';
    final settings = SettingsController(nativeBridge: NativeBridge.instance);

    final result = await settings.workspace.chooseSaveFolderPath();
    final prefs = await SharedPreferences.getInstance();

    expect(result, '/tmp/Exports');
    expect(settings.workspace.saveFolderPath, '/tmp/Exports');
    expect(prefs.getString('saveFolderPath'), '/tmp/Exports');
  });

  test('chooseSaveFolderPath keeps current folder on cancel', () async {
    final settings = SettingsController(nativeBridge: NativeBridge.instance);
    chosenFolder = '/tmp/Current';
    await settings.workspace.chooseSaveFolderPath();

    chosenFolder = null;
    final result = await settings.workspace.chooseSaveFolderPath();
    final prefs = await SharedPreferences.getInstance();

    expect(result, isNull);
    expect(settings.workspace.saveFolderPath, '/tmp/Current');
    expect(prefs.getString('saveFolderPath'), '/tmp/Current');
  });

  test('openSaveFolderOncePerSession opens only once', () async {
    final settings = SettingsController(nativeBridge: NativeBridge.instance);

    final first = await settings.workspace.openSaveFolderOncePerSession();
    final second = await settings.workspace.openSaveFolderOncePerSession();

    expect(first, isTrue);
    expect(second, isFalse);
    expect(openSaveFolderCalls, 1);
  });

  test('session guard resets on new app session', () async {
    final firstSession = SettingsController(
      nativeBridge: NativeBridge.instance,
    );
    final secondSession = SettingsController(
      nativeBridge: NativeBridge.instance,
    );

    final first = await firstSession.workspace.openSaveFolderOncePerSession();
    final second = await secondSession.workspace.openSaveFolderOncePerSession();

    expect(first, isTrue);
    expect(second, isTrue);
    expect(openSaveFolderCalls, 2);
  });

  test('warnBeforeClosingUnexportedRecording defaults to true', () {
    final settings = SettingsController(nativeBridge: NativeBridge.instance);

    expect(settings.workspace.warnBeforeClosingUnexportedRecording, isTrue);
  });

  test('showPreRecordingActionBar defaults to true', () {
    final settings = SettingsController(nativeBridge: NativeBridge.instance);

    expect(settings.workspace.showPreRecordingActionBar, isTrue);
  });

  test(
    'loadPreferences restores persisted showPreRecordingActionBar value',
    () async {
      SharedPreferences.setMockInitialValues({
        'showPreRecordingActionBar': false,
      });
      final settings = SettingsController(nativeBridge: NativeBridge.instance);

      await settings.loadPreferences();

      expect(settings.workspace.showPreRecordingActionBar, isFalse);
    },
  );

  test('updateWarnBeforeClosingUnexportedRecording persists false', () async {
    final settings = SettingsController(nativeBridge: NativeBridge.instance);

    await settings.workspace.updateWarnBeforeClosingUnexportedRecording(false);
    final prefs = await SharedPreferences.getInstance();

    expect(settings.workspace.warnBeforeClosingUnexportedRecording, isFalse);
    expect(prefs.getBool('warnBeforeClosingUnexportedRecording'), isFalse);
  });

  test(
    'updateWarnBeforeClosingUnexportedRecording persists true again',
    () async {
      final settings = SettingsController(nativeBridge: NativeBridge.instance);

      await settings.workspace.updateWarnBeforeClosingUnexportedRecording(
        false,
      );
      await settings.workspace.updateWarnBeforeClosingUnexportedRecording(true);
      final prefs = await SharedPreferences.getInstance();

      expect(settings.workspace.warnBeforeClosingUnexportedRecording, isTrue);
      expect(prefs.getBool('warnBeforeClosingUnexportedRecording'), isTrue);
    },
  );

  test(
    'updateShowPreRecordingActionBar persists false and invokes native',
    () async {
      final settings = SettingsController(nativeBridge: NativeBridge.instance);

      await settings.workspace.updateShowPreRecordingActionBar(false);
      final prefs = await SharedPreferences.getInstance();

      expect(settings.workspace.showPreRecordingActionBar, isFalse);
      expect(prefs.getBool('showPreRecordingActionBar'), isFalse);
      expect(preRecordingBarEnabledValues, [false]);
    },
  );

  test(
    'updateShowPreRecordingActionBar persists true and invokes native',
    () async {
      final settings = SettingsController(nativeBridge: NativeBridge.instance);

      await settings.workspace.updateShowPreRecordingActionBar(false);
      await settings.workspace.updateShowPreRecordingActionBar(true);
      final prefs = await SharedPreferences.getInstance();

      expect(settings.workspace.showPreRecordingActionBar, isTrue);
      expect(prefs.getBool('showPreRecordingActionBar'), isTrue);
      expect(preRecordingBarEnabledValues, [false, true]);
    },
  );
}
