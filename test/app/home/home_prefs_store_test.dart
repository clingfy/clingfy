import 'package:clingfy/app/home/home_prefs_store.dart';
import 'package:clingfy/core/models/app_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('load reads persisted indicator and target mode', () async {
    SharedPreferences.setMockInitialValues({
      HomePrefsStore.indicatorPinnedKey: true,
      HomePrefsStore.displayTargetModeKey:
          DisplayTargetMode.singleAppWindow.index,
    });

    final prefsStore = HomePrefsStore();
    final prefs = await prefsStore.load();

    expect(prefs.indicatorPinned, isTrue);
    expect(prefs.targetMode, DisplayTargetMode.singleAppWindow);
  });

  test('save methods persist values', () async {
    SharedPreferences.setMockInitialValues({});
    final prefsStore = HomePrefsStore();

    await prefsStore.saveIndicatorPinned(true);
    await prefsStore.saveDisplayTargetMode(DisplayTargetMode.areaRecording);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(HomePrefsStore.indicatorPinnedKey), isTrue);
    expect(
      prefs.getInt(HomePrefsStore.displayTargetModeKey),
      DisplayTargetMode.areaRecording.index,
    );
  });
}
