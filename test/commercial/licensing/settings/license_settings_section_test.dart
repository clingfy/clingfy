import 'package:clingfy/commercial/licensing/license_controller.dart';
import 'package:clingfy/l10n/app_localizations.dart';
import 'package:clingfy/commercial/licensing/models/license_plan.dart';
import 'package:clingfy/commercial/licensing/license_service.dart';
import 'package:clingfy/commercial/licensing/settings/license_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  LicenseController buildController({
    required LicenseState state,
    String? currentKey,
    bool isLoading = false,
  }) {
    final controller = LicenseController();
    controller.state = state;
    controller.currentKey = currentKey;
    controller.isLoading = isLoading;
    return controller;
  }

  LicenseState buildState({
    LicensePlan plan = LicensePlan.starter,
    bool entitledPro = false,
    bool isUpdateCovered = false,
    int trialExportsRemaining = 0,
    DateTime? memberSince,
    DateTime? activatedAt,
    DateTime? updatesExpiresAt,
    String message = 'ok',
  }) {
    return LicenseState(
      isValid: true,
      entitledPro: entitledPro,
      plan: plan.wireValue,
      isUpdateCovered: isUpdateCovered,
      trialExportsRemaining: trialExportsRemaining,
      memberSince: memberSince,
      activatedAt: activatedAt,
      updatesExpiresAt: updatesExpiresAt,
      message: message,
    );
  }

  Widget buildTestApp(
    LicenseController controller, {
    Future<bool?> Function(BuildContext context)? paywallLauncher,
  }) {
    return ChangeNotifierProvider<LicenseController>.value(
      value: controller,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            MacosTheme(data: MacosThemeData.light(), child: child!),
        home: Scaffold(
          body: LicenseSettingsSection(paywallLauncher: paywallLauncher),
        ),
      ),
    );
  }

  testWidgets('renders current license section cards and device controls', (
    tester,
  ) async {
    final controller = buildController(
      state: buildState(
        plan: LicensePlan.starter,
        entitledPro: false,
        isUpdateCovered: false,
      ),
    );

    await tester.pumpWidget(buildTestApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('License summary'), findsOneWidget);
    expect(find.text('License details'), findsOneWidget);
    expect(find.text('Next action'), findsOneWidget);
  });

  testWidgets('shows state-driven CTA labels', (tester) async {
    final now = DateTime.now();

    final starter = buildController(
      state: buildState(plan: LicensePlan.starter),
    );
    await tester.pumpWidget(buildTestApp(starter));
    await tester.pumpAndSettle();
    expect(find.text('Activate key or upgrade'), findsWidgets);

    final trial = buildController(
      state: buildState(
        plan: LicensePlan.trial,
        entitledPro: true,
        isUpdateCovered: true,
        trialExportsRemaining: 3,
      ),
    );
    await tester.pumpWidget(buildTestApp(trial));
    await tester.pumpAndSettle();
    expect(find.text('Upgrade to Pro'), findsOneWidget);
    expect(find.text('Have a key? Activate it'), findsOneWidget);

    final subscription = buildController(
      state: buildState(
        plan: LicensePlan.subscription,
        entitledPro: true,
        isUpdateCovered: true,
      ),
      currentKey: 'license-key-for-test-only',
    );
    await tester.pumpWidget(buildTestApp(subscription));
    await tester.pumpAndSettle();
    expect(find.text('Subscription active'), findsOneWidget);

    final lifetimeHealthy = buildController(
      state: buildState(
        plan: LicensePlan.lifetime,
        entitledPro: true,
        isUpdateCovered: true,
        updatesExpiresAt: now.add(const Duration(days: 60)),
      ),
      currentKey: 'license-key-for-test-only',
    );
    await tester.pumpWidget(buildTestApp(lifetimeHealthy));
    await tester.pumpAndSettle();
    expect(find.text('Lifetime license active'), findsOneWidget);

    final lifetimeExpiring = buildController(
      state: buildState(
        plan: LicensePlan.lifetime,
        entitledPro: true,
        isUpdateCovered: true,
        updatesExpiresAt: now.add(const Duration(days: 12)),
      ),
      currentKey: 'license-key-for-test-only',
    );
    await tester.pumpWidget(buildTestApp(lifetimeExpiring));
    await tester.pumpAndSettle();
    expect(find.text('Extend updates'), findsOneWidget);
  });

  testWidgets('shows masked key instead of full license key', (tester) async {
    const rawKey = 'raw-license-key-for-test-F9';
    final controller = buildController(
      state: buildState(
        plan: LicensePlan.lifetime,
        entitledPro: true,
        isUpdateCovered: true,
      ),
      currentKey: rawKey,
    );

    await tester.pumpWidget(buildTestApp(controller));
    await tester.pumpAndSettle();

    expect(find.text(rawKey), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            widget.data!.contains('•') &&
            widget.data!.contains('F9'),
      ),
      findsWidgets,
    );
  });

  testWidgets('activation success triggers one-shot celebration and feedback', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var paywallCalls = 0;
    final controller = buildController(
      state: buildState(plan: LicensePlan.starter),
    );

    await tester.pumpWidget(
      buildTestApp(
        controller,
        paywallLauncher: (_) async {
          paywallCalls++;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Activate key or upgrade').first);
    await tester.pump();

    expect(paywallCalls, 1);
    expect(find.byKey(const Key('license-celebration')), findsOneWidget);
    expect(find.text('Pro unlocked successfully!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.byKey(const Key('license-celebration')), findsNothing);
  });
}
