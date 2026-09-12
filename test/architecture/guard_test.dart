import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  Iterable<File> dartUnder(String root) => Directory(root)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  Iterable<File> presentation() => dartUnder('lib/features')
      .where((f) => f.path.contains('/presentation/'));

  test('presentation does not import raw http or shared_preferences', () {
    for (final file in presentation()) {
      final src = file.readAsStringSync();
      expect(src.contains("package:http/http.dart"), isFalse, reason: file.path);
      expect(
        src.contains("package:shared_preferences/shared_preferences.dart"),
        isFalse,
        reason: file.path,
      );
      expect(src.contains('sk_live'), isFalse, reason: file.path);
      expect(src.contains("package:movera_rider/core/api/api_client.dart"), isFalse,
          reason: file.path);
    }
  });

  test('no SharedPreferences token storage', () {
    final token = File('lib/core/auth/token_store.dart').readAsStringSync();
    expect(token.contains("package:shared_preferences"), isFalse);
    final secure = File('lib/core/auth/secure_token_store.dart').readAsStringSync();
    expect(secure.contains("package:shared_preferences"), isFalse);
  });

  test('finding driver assignment is not a widget Timer', () {
    final ui = File(
      'lib/features/finding_driver/presentation/finding_drivers.dart',
    ).readAsStringSync();
    expect(ui.contains('Timer(Duration(seconds: 12)'), isFalse);
  });

  test('home does not own ride restoration', () {
    final home = File('lib/features/home/presentation/home.dart').readAsStringSync();
    expect(home.contains('_restoreActiveRide'), isFalse);
    expect(home.contains('RideSnapshotStore'), isFalse);
  });

  test('home does not draw a trip polyline', () {
    final home = File('lib/features/home/presentation/home.dart').readAsStringSync();
    expect(home.contains('Polyline('), isFalse);
    expect(home.contains('polylines:'), isFalse);
  });

  test('waiting screen does not markArriving on open', () {
    final ui = File(
      'lib/features/active_ride/presentation/waiting_for_driver.dart',
    ).readAsStringSync();
    expect(ui.contains('markArriving'), isFalse);
  });

  test('never disposes GoogleMapController', () {
    for (final file in dartUnder('lib')) {
      final src = file.readAsStringSync();
      expect(src.contains('GoogleMapController.dispose'), isFalse, reason: file.path);
      expect(
        RegExp(r'_mapController\?\.dispose|_mapController\.dispose').hasMatch(src),
        isFalse,
        reason: file.path,
      );
    }
  });

  test('presentation has no catalog fare table', () {
    for (final file in presentation()) {
      final src = file.readAsStringSync();
      expect(src.contains("'movera': 259"), isFalse, reason: file.path);
    }
  });

  test('presentation does not import feature data repositories', () {
    final banned = RegExp(
      r'package:movera_rider/features/[^/]+/data/',
    );
    for (final file in presentation()) {
      final src = file.readAsStringSync();
      expect(banned.hasMatch(src), isFalse, reason: file.path);
    }
  });

  test('presentation does not construct API, booking, or payment clients', () {
    for (final file in presentation()) {
      final src = file.readAsStringSync();
      expect(src.contains('ApiClient('), isFalse, reason: file.path);
      expect(src.contains('InProcessMockClient('), isFalse, reason: file.path);
      expect(src.contains('MockPaymentGateway('), isFalse, reason: file.path);
      expect(src.contains('MockRideRealtime('), isFalse, reason: file.path);
    }
  });

  test('home does not import address repository', () {
    final home = File('lib/features/home/presentation/home.dart').readAsStringSync();
    expect(home.contains('home_repository.dart'), isFalse);
    expect(home.contains('HomeAddressRepository'), isFalse);
  });

  test('select ride widget is not the source of ride/payment truth', () {
    final ui = File(
      'lib/features/ride_selection/presentation/select_ride.dart',
    ).readAsStringSync();
    expect(ui.contains("String _selectedRideId"), isFalse);
    expect(ui.contains('int _selectedPayment'), isFalse);
    expect(ui.contains('DateTime? _scheduledFor'), isFalse);
  });

  test('waiting screen does not hardcode driver plate', () {
    final ui = File(
      'lib/features/active_ride/presentation/waiting_for_driver.dart',
    ).readAsStringSync();
    expect(ui.contains('"L - 2323 F"'), isFalse);
  });

  test('home does not own map overlay set fields', () {
    final home = File('lib/features/home/presentation/home.dart').readAsStringSync();
    expect(home.contains('Set<Marker> _markers ='), isFalse);
    expect(home.contains('Set<Circle> _locationCircles ='), isFalse);
    expect(home.contains('Set<Polygon> _locationDirection ='), isFalse);
    expect(home.contains('HomeAddressRepository'), isFalse);
  });

  test('web heading start is idempotent and gesture-armed', () {
    final html = File('web/index.html').readAsStringSync();
    expect(html.contains('moveraStartHeading'), isTrue);
    expect(html.contains('moveraHeadingStartPromise'), isTrue);
    expect(html.contains('moveraInjectHeading'), isTrue);
    expect(html.contains('moveraStopHeading'), isTrue);
    expect(html.contains('moveraArmHeadingFromGesture'), isTrue);
    expect(html.contains('moveraRequestHeadingFromGesture'), isTrue);
    expect(html.contains("addEventListener('pointerdown', arm, true)"), isTrue);
    expect(html.contains("addEventListener('touchstart', arm, true)"), isTrue);
    expect(html.contains("addEventListener('touchend', arm, true)"), isTrue);
    expect(html.contains('DeviceOrientationEvent.requestPermission().then'), isTrue);
    expect(html.contains('webkitCompassHeading'), isTrue);
    expect(html.contains('moveraScreenAngle'), isTrue);
  });

  test('home does not add a compass permission screen', () {
    final home = File('lib/features/home/presentation/home.dart').readAsStringSync();
    expect(home.contains('Enable compass'), isFalse);
    expect(home.contains('Motion permission'), isFalse);
    expect(home.contains('Device orientation'), isFalse);
  });

  test('select ride does not keep parallel quote expiry state', () {
    final ui = File(
      'lib/features/ride_selection/presentation/select_ride.dart',
    ).readAsStringSync();
    expect(ui.contains('Map<String, DateTime> _quoteExpires'), isFalse);
    expect(ui.contains('Map<String, String> _quoteIds'), isFalse);
  });
}

