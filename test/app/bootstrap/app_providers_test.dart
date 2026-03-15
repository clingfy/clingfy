import 'package:clingfy/app/bootstrap/app_providers.dart';
import 'package:clingfy/core/devices/device_controller.dart';
import 'package:clingfy/commercial/licensing/license_controller.dart';
import 'package:clingfy/app/home/overlay/overlay_controller.dart';
import 'package:clingfy/core/preview/player_controller.dart';
import 'package:clingfy/app/home/post_processing/post_processing_controller.dart';
import 'package:clingfy/app/home/recording/recording_controller.dart';
import 'package:clingfy/core/bridges/native_bridge.dart';
import 'package:clingfy/app/settings/settings_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/native_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await installCommonNativeMocks();
  });

  tearDown(() async {
    await clearCommonNativeMocks();
  });

  testWidgets('provider graph creates expected controllers', (tester) async {
    final nativeBridge = NativeBridge.instance;
    final settingsController = SettingsController(nativeBridge: nativeBridge);

    late RecordingController recordingController;
    late PlayerController playerController;
    late DeviceController deviceController;
    late LicenseController licenseController;
    late OverlayController overlayController;
    late PostProcessingController postProcessingController;
    late SettingsController providedSettingsController;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AppProviders(
          settingsController: settingsController,
          nativeBridge: nativeBridge,
          child: Builder(
            builder: (context) {
              recordingController = context.read<RecordingController>();
              playerController = context.read<PlayerController>();
              deviceController = context.read<DeviceController>();
              licenseController = context.read<LicenseController>();
              overlayController = context.read<OverlayController>();
              postProcessingController = context
                  .read<PostProcessingController>();
              providedSettingsController = context.read<SettingsController>();
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(recordingController, isA<RecordingController>());
    expect(playerController, isA<PlayerController>());
    expect(deviceController, isA<DeviceController>());
    expect(licenseController, isA<LicenseController>());
    expect(overlayController, isA<OverlayController>());
    expect(postProcessingController, isA<PostProcessingController>());
    expect(providedSettingsController, same(settingsController));
  });
}
