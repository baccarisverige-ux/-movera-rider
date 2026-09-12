abstract class BookingRepository {
  Future<void> refresh();
}

class LocalBookingRepository implements BookingRepository {
  @override
  Future<void> refresh() async {}
}
