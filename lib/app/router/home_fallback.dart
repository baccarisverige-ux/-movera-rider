import 'package:flutter/widgets.dart';

/// Lets low-level restore/coordination code (e.g. RideRestoreCoordinator)
/// reach the app's Home screen as a fallback destination without importing
/// `features/home/presentation/home.dart` directly - that import would
/// create a circular dependency, since home.dart itself needs
/// RideRestoreCoordinator (for takeSearchInterrupted()).
///
/// `bootstrap.dart` registers the real builder once at app startup, before
/// any restore logic can run.
typedef HomeBuilder = Widget Function();

HomeBuilder? _homeBuilder;

void registerHomeBuilder(HomeBuilder builder) => _homeBuilder = builder;

Widget buildHome() {
  final builder = _homeBuilder;
  assert(builder != null, 'registerHomeBuilder must run before buildHome is used');
  return builder?.call() ?? const SizedBox.shrink();
}
