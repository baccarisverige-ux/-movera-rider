import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/data/local_reservation_repository.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/domain/reservation_status.dart';

void main() {
  ReservationController controller() {
    return ReservationController(
      store: LocalReservationRepository(
        storage: MemoryReservationStorage(),
        nextId: () => 'rsv_ctrl',
      ),
    );
  }

  final draft = ReservationDraft(
    scheduledPickupAt: DateTime(2026, 9, 23, 6, 55),
    pickup: const ReservationPlace(label: 'Klockarvägen 37'),
    destination: const ReservationPlace(label: 'T-Centralen'),
    categoryId: 'comfort',
    categoryName: 'Comfort',
    categoryImage: 'assets/images/rides/comfort.png',
    price: 339,
    paymentMethod: 'Cash',
  );

  test('opening details does not create another reservation', () async {
    final c = controller();
    await c.create(draft);
    expect(c.all, hasLength(1));
    expect(c.byId('rsv_ctrl')?.reservationId, 'rsv_ctrl');
    expect(c.byId('rsv_ctrl')?.reservationId, 'rsv_ctrl');
    expect(c.all, hasLength(1));
  });

  test('tabs split upcoming completed cancelled', () async {
    final c = controller();
    await c.create(draft);
    expect(c.upcoming(), hasLength(1));
    expect(c.cancelled(), isEmpty);
    await c.cancel('rsv_ctrl', reason: 'plans_changed');
    expect(c.upcoming(), isEmpty);
    expect(c.cancelled(), hasLength(1));
    expect(c.completed(), isEmpty);
  });

  test('mock driver assignment is the same reservation', () async {
    final c = controller();
    await c.create(draft);
    await c.assignMockDriver('rsv_ctrl');
    final ride = c.byId('rsv_ctrl')!;
    expect(ride.status, ReservationStatus.driverAssigned);
    expect(ride.driverAssigned, isTrue);
    expect(c.upcoming(), hasLength(1));
  });

  test('plan return waits for explicit create', () async {
    var n = 0;
    final c = ReservationController(
      store: LocalReservationRepository(
        storage: MemoryReservationStorage(),
        nextId: () => 'rsv_${++n}',
      ),
    );
    final origin = await c.create(draft);
    expect(c.all, hasLength(1));
    final ret = await c.planReturn(
      origin,
      scheduledPickupAt: DateTime(2026, 9, 24, 18, 30),
    );
    expect(ret.reservationId, isNot(origin.reservationId));
    expect(ret.pickup.label, origin.destination.label);
    expect(ret.destination.label, origin.pickup.label);
    expect(c.all, hasLength(2));
  });
}
