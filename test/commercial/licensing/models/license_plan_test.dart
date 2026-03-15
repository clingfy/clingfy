import 'package:clingfy/commercial/licensing/models/license_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('license plan parser handles known and unknown values', () {
    expect(licensePlanFromWire('trial'), LicensePlan.trial);
    expect(licensePlanFromWire('lifetime'), LicensePlan.lifetime);
    expect(licensePlanFromWire('subscription'), LicensePlan.subscription);
    expect(licensePlanFromWire('starter'), LicensePlan.starter);
    expect(licensePlanFromWire('legacy-plan'), LicensePlan.unknown);
    expect(licensePlanFromWire(null), LicensePlan.unknown);
  });
}
