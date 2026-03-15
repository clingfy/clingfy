import 'package:shared_preferences/shared_preferences.dart';

class PermissionsOnboardingStore {
  static const _seenKey = 'onboarding_seen_v1';
  static const _stepKey = 'onboarding_step_v1';

  Future<bool> getSeen() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_seenKey) ?? false;
  }

  Future<void> setSeen(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_seenKey, value);
  }

  Future<int> getStep() async {
    final sp = await SharedPreferences.getInstance();
    final step = sp.getInt(_stepKey) ?? 0;
    return _clampStep(step);
  }

  Future<void> setStep(int step) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_stepKey, _clampStep(step));
  }

  Future<void> resetStep() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_stepKey);
  }

  int _clampStep(int step) => step < 0 ? 0 : step;
}
