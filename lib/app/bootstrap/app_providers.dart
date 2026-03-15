import 'package:clingfy/core/devices/device_controller.dart';
import 'package:clingfy/commercial/licensing/license_controller.dart';
import 'package:clingfy/app/home/overlay/overlay_controller.dart';
import 'package:clingfy/core/preview/player_controller.dart';
import 'package:clingfy/app/home/post_processing/post_processing_controller.dart';
import 'package:clingfy/app/home/recording/recording_controller.dart';
import 'package:clingfy/core/bridges/native_bridge.dart';
import 'package:clingfy/app/settings/settings_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({
    super.key,
    required this.settingsController,
    required this.nativeBridge,
    required this.child,
  });

  final SettingsController settingsController;
  final NativeBridge nativeBridge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => RecordingController(
            nativeBridge: nativeBridge,
            settings: settingsController,
          ),
        ),
        ChangeNotifierProxyProvider<RecordingController, PlayerController>(
          create: (_) => PlayerController(nativeBridge: nativeBridge),
          update: (_, recording, player) {
            final resolvedPlayer =
                player ?? PlayerController(nativeBridge: nativeBridge);
            resolvedPlayer.bindWorkflow(recording);
            return resolvedPlayer;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => DeviceController(nativeBridge: nativeBridge),
        ),
        ChangeNotifierProvider(
          create: (_) => LicenseController()..initialize(),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => OverlayController(bridge: nativeBridge),
        ),
        ChangeNotifierProxyProvider<PlayerController, PostProcessingController>(
          create: (context) => PostProcessingController(
            player: context.read<PlayerController>(),
            settings: settingsController,
            channel: nativeBridge,
          ),
          update: (_, player, post) {
            return post ??
                PostProcessingController(
                  settings: settingsController,
                  player: player,
                  channel: nativeBridge,
                );
          },
        ),
        ChangeNotifierProvider.value(value: settingsController),
      ],
      child: child,
    );
  }
}
