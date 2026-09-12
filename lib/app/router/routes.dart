/// Named routes for the approved Rider flow.
/// Screens still push with existing transitions; names are the contract.
abstract final class AppRoutes {
  static const home = '/';
  static const selectRide = '/ride/select';
  static const findingDriver = '/ride/finding';
  static const waitingForDriver = '/ride/waiting';
  static const rideCompleted = '/ride/completed';
  static const wallet = '/wallet';
  static const payments = '/payments';
  static const rideHistory = '/history';
  static const support = '/support';
  static const schedule = '/schedule';
  static const profile = '/profile';
}
