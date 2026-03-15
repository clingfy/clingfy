import 'package:clingfy/app/home/models/home_ui_prefs.dart';
import 'package:clingfy/core/models/app_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePrefsStore {
  static const String indicatorPinnedKey = 'indicatorPinned';
  static const String displayTargetModeKey = 'displayTargetMode';

  Future<HomeUiPrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    final indicatorPinned = prefs.getBool(indicatorPinnedKey) ?? false;
    final rawMode =
        prefs.getInt(displayTargetModeKey) ??
        DisplayTargetMode.explicitId.index;
    final safeModeIndex =
        rawMode >= 0 && rawMode < DisplayTargetMode.values.length
        ? rawMode
        : DisplayTargetMode.explicitId.index;

    return HomeUiPrefs(
      indicatorPinned: indicatorPinned,
      targetMode: DisplayTargetMode.values[safeModeIndex],
    );
  }

  Future<void> saveIndicatorPinned(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(indicatorPinnedKey, value);
  }

  Future<void> saveDisplayTargetMode(DisplayTargetMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(displayTargetModeKey, mode.index);
  }
}
