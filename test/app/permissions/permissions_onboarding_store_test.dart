import 'package:clingfy/app/permissions/permissions_onboarding_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seen flag defaults false and persists updates', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PermissionsOnboardingStore();

    expect(await store.getSeen(), isFalse);

    await store.setSeen(true);

    expect(await store.getSeen(), isTrue);
  });

  test('step defaults to zero, clamps negatives, and resets', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PermissionsOnboardingStore();

    expect(await store.getStep(), 0);

    await store.setStep(-2);
    expect(await store.getStep(), 0);

    await store.setStep(3);
    expect(await store.getStep(), 3);

    await store.resetStep();
    expect(await store.getStep(), 0);
  });
}
