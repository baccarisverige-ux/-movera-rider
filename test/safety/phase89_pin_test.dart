import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/app/config/pin_composition.dart';
import 'package:movera_rider/features/safety/domain/ride_pin.dart';
import 'package:movera_rider/features/safety/presentation/safety_ui.dart';

void main() {
  test('missing, malformed and mock PINs cannot pass for server-issued PINs', () {
    expect(RidePin.fromJson(null).isAvailable, isFalse);
    expect(RidePin.fromJson({'pin': '123'}).pin, isEmpty);
    expect(RidePin.fromJson({'pin': '12345'}).pin, isEmpty);
    expect(RidePin.fromJson({'pin': '1234'}).serverAuthoritative, isFalse);
    expect(RidePin.fromJson({'pin': '1234', 'serverAuthoritative': false})
        .serverAuthoritative, isFalse);
  });

  test('mock PIN issuance is rejected by release composition', () {
    for (final flavor in [AppFlavor.production, AppFlavor.staging]) {
      final env = AppEnv(flavor: flavor, apiBaseUrl: 'https://example.test',
          mapsEnabled: false);
      expect(() => PinComposition.validate(
          environment: env, usesMockPinIssuance: true), throwsStateError);
      PinComposition.validate(environment: env, usesMockPinIssuance: false);
    }
  });

  testWidgets('PIN row fits a 320 pixel display', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: SafetyPinCadre(pin: '1234', caption: 'Show to driver'),
    ))));
    expect(tester.takeException(), isNull);
    expect(find.text('4'), findsOneWidget);
  });
}
