import 'package:clingfy/core/bridges/native_bridge.dart';
import 'package:clingfy/app/settings/settings_controller.dart';

class AppScope {
  const AppScope({required this.nativeBridge, required this.settings});

  final NativeBridge nativeBridge;
  final SettingsController settings;
}
