import 'package:clingfy/app/settings/controllers/app_preferences_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loadPreferences restores persisted theme mode', () async {
    SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
    final prefs = await SharedPreferences.getInstance();
    final controller = AppPreferencesController();

    await controller.loadPreferences(prefs);

    expect(controller.themeMode, ThemeMode.dark);
  });

  test('updateThemeMode persists the selected theme mode', () async {
    final controller = AppPreferencesController();

    await controller.updateThemeMode(ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();

    expect(controller.themeMode, ThemeMode.light);
    expect(prefs.getString('themeMode'), ThemeMode.light.name);
  });
}
