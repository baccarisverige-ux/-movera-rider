enum AppLocationPermission {
  notDetermined,
  whileUsing,
  always,
  denied,
  permanentlyDenied,
  servicesDisabled,
  approximate,
  precise,
}

class LocationPermissionService {
  AppLocationPermission status = AppLocationPermission.notDetermined;

  bool get canLocate =>
      status == AppLocationPermission.whileUsing ||
      status == AppLocationPermission.always ||
      status == AppLocationPermission.precise ||
      status == AppLocationPermission.approximate;
}
