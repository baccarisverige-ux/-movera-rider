/// Which Rider sheet is on screen. Does not own ride, price, or matching.
enum RideSheet {
  none,
  whereTo,
  pickup,
  rideSelect,
  notes,
  finding,
  waiting,
  bookNowLater,
  payment,
  cancel,
  cancelReason,
  details,
  safety,
  address,
  later,
}

class SheetCoordinator {
  SheetCoordinator();

  static final instance = SheetCoordinator();

  RideSheet current = RideSheet.none;

  void open(RideSheet sheet) => current = sheet;

  void close(RideSheet sheet) {
    if (current == sheet) current = RideSheet.none;
  }
}
