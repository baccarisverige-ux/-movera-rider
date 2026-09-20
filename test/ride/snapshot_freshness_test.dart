import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

RideSnapshot snap(RideStatus status, {required Duration age}) {
  return RideSnapshot(
    status: status,
    savedAt: DateTime.now().subtract(age),
    pickupAddress: 'Sveavägen 1',
    destinationAddress: 'Arlanda',
    pickupLat: 59.3,
    pickupLng: 18.0,
    destinationLat: 59.65,
    destinationLng: 17.93,
    rideType: 'Movera',
    price: 259,
    paymentMethod: 'Apple Pay',
    rideId: 'r1',
  );
}

/// Seeds storage directly rather than through [RideSnapshotStore.save], so the
/// stored snapshot is exactly as old as the test says.
void seed(RideSnapshot snapshot) {
  SharedPreferences.setMockInitialValues({
    RideSnapshotStore.key: jsonEncode(snapshot.toJson()),
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a search older than twenty minutes is not restored', () async {
    seed(snap(RideStatus.findingDriver, age: const Duration(minutes: 25)));
    expect(await RideSnapshotStore.read(), isNull);
  });

  test('a search inside twenty minutes is restored', () async {
    seed(snap(RideStatus.findingDriver, age: const Duration(minutes: 5)));
    expect(await RideSnapshotStore.read(), isNotNull);
  });

  test('a trip in progress survives past the search window', () async {
    seed(snap(RideStatus.tripInProgress, age: const Duration(minutes: 25)));
    final restored = await RideSnapshotStore.read();
    expect(restored, isNotNull);
    expect(restored!.status, RideStatus.tripInProgress);
  });

  test('a matched ride still expires eventually', () async {
    seed(snap(RideStatus.driverAssigned, age: const Duration(hours: 7)));
    expect(await RideSnapshotStore.read(), isNull);
  });

  test(
    'a finished ride awaiting rating survives past the search window',
    () async {
      seed(snap(RideStatus.ratingPending, age: const Duration(minutes: 40)));
      expect(await RideSnapshotStore.read(), isNotNull);
    },
  );

  test('archival ignores freshness entirely', () async {
    seed(snap(RideStatus.tripInProgress, age: const Duration(days: 3)));
    expect(await RideSnapshotStore.read(), isNull);
    final archived = await RideSnapshotStore.readForArchive();
    expect(archived, isNotNull);
    expect(archived!.status, RideStatus.tripInProgress);
  });
}
