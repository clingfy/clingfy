import 'package:clingfy/app/shell/app_scope.dart';
import 'package:clingfy/app/home/recording/countdown_controller.dart';
import 'package:clingfy/core/devices/device_controller.dart';
import 'package:clingfy/commercial/licensing/license_controller.dart';
import 'package:clingfy/app/home/overlay/overlay_controller.dart';
import 'package:clingfy/app/permissions/permissions_controller.dart';
import 'package:clingfy/core/preview/player_controller.dart';
import 'package:clingfy/app/home/post_processing/post_processing_controller.dart';
import 'package:clingfy/app/home/recording/recording_controller.dart';
import 'package:clingfy/app/home/home_prefs_store.dart';
import 'package:clingfy/app/home/home_ui_state.dart';

class HomeScope {
  const HomeScope({
    required this.app,
    required this.recording,
    required this.player,
    required this.devices,
    required this.overlay,
    required this.permissions,
    required this.post,
    required this.license,
    required this.countdown,
    required this.uiState,
    required this.prefsStore,
  });

  final AppScope app;
  final RecordingController recording;
  final PlayerController player;
  final DeviceController devices;
  final OverlayController overlay;
  final PermissionsController permissions;
  final PostProcessingController post;
  final LicenseController license;
  final CountdownController countdown;
  final HomeUiState uiState;
  final HomePrefsStore prefsStore;
}
