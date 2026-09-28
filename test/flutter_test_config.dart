import 'dart:async';

import 'package:movera_rider/app/router/home_fallback.dart';
import 'package:movera_rider/features/home/presentation/home.dart';

/// Flutter's test runner picks this up automatically for every test file
/// under test/. Phase 143 moved RideRestoreCoordinator's Home fallback
/// behind a runtime-registered builder (see home_fallback.dart) so that
/// ride_restore_coordinator.dart no longer needs to import home.dart
/// directly - production registers the real builder in bootstrap.dart,
/// which no test file runs, so it is registered here instead.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  registerHomeBuilder(() => const Home());
  await testMain();
}
