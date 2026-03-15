import 'dart:convert';

import 'package:clingfy/commercial/licensing/license_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  late Map<String, String> secureStorageValues;

  setUp(() {
    secureStorageValues = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          final arguments =
              (call.arguments as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
          final key = arguments['key']?.toString();
          switch (call.method) {
            case 'write':
              if (key != null) {
                secureStorageValues[key] = arguments['value']?.toString() ?? '';
              }
              return null;
            case 'read':
              if (key == null) {
                return null;
              }
              return secureStorageValues[key];
            case 'delete':
              if (key != null) {
                secureStorageValues.remove(key);
              }
              return null;
            case 'deleteAll':
              secureStorageValues.clear();
              return null;
            case 'readAll':
              return Map<String, String>.from(secureStorageValues);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  test('parses member_since and activated_at when present', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/v1/validate-license');
      return http.Response(
        jsonEncode(<String, dynamic>{
          'valid': true,
          'entitled_pro': true,
          'plan': 'lifetime',
          'is_update_covered': true,
          'trial_exports_remaining': 0,
          'member_since': '2026-02-14T00:00:00Z',
          'activated_at': '2026-02-15T00:00:00Z',
          'updates_expires_at': '2027-02-14T00:00:00Z',
        }),
        200,
      );
    });
    final service = LicenseService(
      httpClient: client,
      hardwareIdProvider: () async => 'hw-test',
    );

    final state = await service.validateLicense('CLINGFY-AAAA-BBBB-CC99');

    expect(state.memberSince, DateTime.parse('2026-02-14T00:00:00Z'));
    expect(state.activatedAt, DateTime.parse('2026-02-15T00:00:00Z'));
    expect(state.updatesExpiresAt, DateTime.parse('2027-02-14T00:00:00Z'));
  });

  test(
    'persists first_activated_at and exposes fallback activated date',
    () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'valid': true,
            'entitled_pro': true,
            'plan': 'lifetime',
            'is_update_covered': true,
            'trial_exports_remaining': 0,
          }),
          200,
        );
      });
      final service = LicenseService(
        httpClient: client,
        hardwareIdProvider: () async => 'hw-test',
      );

      final state = await service.validateLicense('CLINGFY-AAAA-BBBB-CC99');

      expect(secureStorageValues['first_activated_at'], isNotNull);
      expect(state.activatedAt, isNotNull);
    },
  );

  test('first_activated_at fallback is not overwritten once set', () async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount += 1;
      if (requestCount == 1) {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'valid': true,
            'entitled_pro': true,
            'plan': 'lifetime',
            'is_update_covered': true,
            'trial_exports_remaining': 0,
            'member_since': '2026-01-10T00:00:00Z',
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode(<String, dynamic>{
          'valid': true,
          'entitled_pro': true,
          'plan': 'lifetime',
          'is_update_covered': true,
          'trial_exports_remaining': 0,
          'member_since': '2026-03-01T00:00:00Z',
        }),
        200,
      );
    });
    final service = LicenseService(
      httpClient: client,
      hardwareIdProvider: () async => 'hw-test',
    );

    await service.validateLicense('CLINGFY-AAAA-BBBB-CC99');
    final firstValue = secureStorageValues['first_activated_at'];
    expect(firstValue, isNotNull);

    await service.validateLicense('CLINGFY-AAAA-BBBB-CC99');
    final secondValue = secureStorageValues['first_activated_at'];

    expect(secondValue, firstValue);
  });
}
