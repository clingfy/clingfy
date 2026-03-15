import 'package:clingfy/app/bootstrap/app_providers.dart';
import 'package:clingfy/app/home/home_page.dart';
import 'package:clingfy/app/permissions/widgets/permissions_gate.dart';
import 'package:clingfy/app/settings/settings_controller.dart';
import 'package:clingfy/app/shell/platform_app.dart';
import 'package:clingfy/core/bridges/native_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers/native_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await installCommonNativeMocks(
      screenRecordingGranted: false,
      onboardingSeen: false,
    );
  });

  tearDown(() async {
    await clearCommonNativeMocks();
  });

  testWidgets('platform app smoke test renders without main.dart coupling', (
    tester,
  ) async {
    final nativeBridge = NativeBridge.instance;
    final settingsController = SettingsController(nativeBridge: nativeBridge);
    await settingsController.loadPreferences();

    await tester.pumpWidget(
      AppProviders(
        settingsController: settingsController,
        nativeBridge: nativeBridge,
        child: PlatformApp(
          settingsController: settingsController,
          nativeBridge: nativeBridge,
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(PlatformApp), findsOneWidget);
    expect(find.byType(PermissionsGate), findsOneWidget);
    final gate = tester.widget<PermissionsGate>(find.byType(PermissionsGate));
    expect(gate.child, isA<HomePage>());
  });
}
