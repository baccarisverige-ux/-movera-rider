abstract class RideBookingRepository {
  Future<void> refresh();
}

class LocalRideBookingRepository implements RideBookingRepository {
  @override
  Future<void> refresh() async {}
}
