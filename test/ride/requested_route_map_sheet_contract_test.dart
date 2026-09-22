import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Plan your ride uses location badges in the route-line slot', () {
    final home = File(
      'lib/features/home/presentation/home.dart',
    ).readAsStringSync();

    expect(home, contains('child: badgeColor != null'));
    expect(home, contains('PremiumRouteLocationBadge('));
    expect(home, contains('size: ResSize.h * 27'));
    expect(
      home,
      isNot(contains("shape: field == 'destination'")),
      reason: 'Pickup/destination circle/square placeholders must be removed.',
    );
  });

  test('Finding and Waiting keep only the Movera rider puck layer', () {
    final finding = File(
      'lib/features/finding_driver/presentation/finding_drivers.dart',
    ).readAsStringSync();
    final waiting = File(
      'lib/features/active_ride/presentation/waiting_for_driver.dart',
    ).readAsStringSync();

    expect(finding, contains('myLocationEnabled: false'));
    expect(waiting, contains('myLocationEnabled: false'));
    expect(finding, isNot(contains('BitmapDescriptor.hueRed')));
    expect(waiting, isNot(contains('BitmapDescriptor.hueRed')));
    expect(finding, contains('icon: _riderPuck!'));
    expect(waiting, contains('icon: _riderPuck!'));

    final markerSource = File(
      'lib/shared/widgets/movera_map_markers.dart',
    ).readAsStringSync();
    final riderPuckSource = markerSource.split(
      'class MoveraVehicleMarker',
    ).first;
    expect(riderPuckSource, isNot(contains('BitmapDescriptor.defaultMarker')));
  });

  test('Waiting sheet has collapsed, middle and expanded snaps', () {
    final waiting = File(
      'lib/features/active_ride/presentation/waiting_for_driver.dart',
    ).readAsStringSync();

    expect(waiting, contains('_collapsedSheet(MediaQueryData media)'));
    expect(
      waiting,
      contains('SheetOffset.absolute(_collapsedSheet(media))'),
    );
    expect(waiting, contains('SheetOffset.absolute(_minSheet(media))'));
    expect(waiting, contains('SheetOffset.absolute(_maxSheet(media))'));
    expect(
      waiting,
      contains('bottom: 0,'),
      reason: 'Map must continue behind the lower collapsed sheet.',
    );
  });
}
