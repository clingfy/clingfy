import 'package:clingfy/commercial/licensing/license_controller.dart';
import 'package:clingfy/commercial/licensing/models/license_plan.dart';
import 'package:clingfy/commercial/licensing/license_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LicenseState buildState({
    required LicensePlan plan,
    required bool entitledPro,
    required bool isUpdateCovered,
    int trialExportsRemaining = 0,
    DateTime? updatesExpiresAt,
  }) {
    return LicenseState(
      isValid: true,
      entitledPro: entitledPro,
      plan: plan.wireValue,
      isUpdateCovered: isUpdateCovered,
      trialExportsRemaining: trialExportsRemaining,
      memberSince: null,
      activatedAt: null,
      updatesExpiresAt: updatesExpiresAt,
      message: 'ok',
    );
  }

  test('isUpdatesExpiringSoon uses 30-day threshold for lifetime only', () {
    final now = DateTime.now();
    final controller = LicenseController();

    controller.state = buildState(
      plan: LicensePlan.lifetime,
      entitledPro: true,
      isUpdateCovered: true,
      updatesExpiresAt: now.add(const Duration(days: 30)),
    );
    expect(controller.isUpdatesExpiringSoon, isTrue);

    controller.state = buildState(
      plan: LicensePlan.lifetime,
      entitledPro: true,
      isUpdateCovered: true,
      updatesExpiresAt: now.add(const Duration(days: 32)),
    );
    expect(controller.isUpdatesExpiringSoon, isFalse);

    controller.state = buildState(
      plan: LicensePlan.subscription,
      entitledPro: true,
      isUpdateCovered: true,
      updatesExpiresAt: now.add(const Duration(days: 10)),
    );
    expect(controller.isUpdatesExpiringSoon, isFalse);
  });

  test('primaryLicenseActionType maps correctly by plan and coverage', () {
    final now = DateTime.now();
    final controller = LicenseController();

    controller.state = buildState(
      plan: LicensePlan.starter,
      entitledPro: false,
      isUpdateCovered: false,
    );
    controller.currentKey = null;
    expect(
      controller.primaryLicenseActionType,
      LicensePrimaryAction.activateOrUpgrade,
    );

    controller.state = buildState(
      plan: LicensePlan.trial,
      entitledPro: true,
      isUpdateCovered: true,
      trialExportsRemaining: 2,
    );
    expect(
      controller.primaryLicenseActionType,
      LicensePrimaryAction.upgradeToPro,
    );

    controller.state = buildState(
      plan: LicensePlan.subscription,
      entitledPro: true,
      isUpdateCovered: true,
    );
    controller.currentKey = 'CLINGFY-AAAA-BBBB-CC99';
    expect(
      controller.primaryLicenseActionType,
      LicensePrimaryAction.subscriptionActive,
    );

    controller.state = buildState(
      plan: LicensePlan.lifetime,
      entitledPro: true,
      isUpdateCovered: true,
      updatesExpiresAt: now.add(const Duration(days: 60)),
    );
    expect(
      controller.primaryLicenseActionType,
      LicensePrimaryAction.lifetimeActive,
    );

    controller.state = buildState(
      plan: LicensePlan.lifetime,
      entitledPro: true,
      isUpdateCovered: true,
      updatesExpiresAt: now.add(const Duration(days: 8)),
    );
    expect(
      controller.primaryLicenseActionType,
      LicensePrimaryAction.extendUpdates,
    );

    controller.state = buildState(
      plan: LicensePlan.lifetime,
      entitledPro: false,
      isUpdateCovered: false,
      updatesExpiresAt: now.subtract(const Duration(days: 2)),
    );
    expect(
      controller.primaryLicenseActionType,
      LicensePrimaryAction.extendUpdates,
    );
  });

  test('hasLinkedKey and canExtendUpdates helpers are correct', () {
    final now = DateTime.now();
    final controller = LicenseController();

    controller.state = buildState(
      plan: LicensePlan.lifetime,
      entitledPro: true,
      isUpdateCovered: true,
      updatesExpiresAt: now.add(const Duration(days: 20)),
    );
    controller.currentKey = '';
    expect(controller.hasLinkedKey, isFalse);
    expect(controller.canExtendUpdates, isTrue);

    controller.currentKey = 'CLINGFY-KEY1-KEY2-KEY3';
    expect(controller.hasLinkedKey, isTrue);

    controller.state = buildState(
      plan: LicensePlan.lifetime,
      entitledPro: true,
      isUpdateCovered: true,
      updatesExpiresAt: now.add(const Duration(days: 60)),
    );
    expect(controller.canExtendUpdates, isFalse);
  });
}
