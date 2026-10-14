import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/core/contracts/repository_authority.dart';

/// One rider-facing repository in the composition root, with whether its
/// feature is switched on for this build.
class RepositorySurface {
  const RepositorySurface(
    this.name, {
    required this.implementation,
    this.enabled = true,
  });

  final String name;
  final Object implementation;
  final bool enabled;
}

/// Release guard for repositories, next to `TransportComposition` for
/// transports (ARCH-7).
///
/// In staging/production every rider-facing repository must be backed by the
/// server ([ServerBackedRepository]). A feature whose server side does not
/// exist yet must be switched off by its flag and composed with a
/// fail-closed [FeatureOffRepository]. A device-only implementation
/// (SharedPreferences, memory) is never allowed, whatever the flag says,
/// because a screen could still reach it.
abstract final class RepositoryComposition {
  static void validate({
    required AppEnv environment,
    required List<RepositorySurface> surfaces,
  }) {
    if (!environment.isReleaseLike) return;
    final rejected = <String>[
      for (final surface in surfaces)
        if (surface.enabled
            ? surface.implementation is! ServerBackedRepository
            : surface.implementation is! ServerBackedRepository &&
                  surface.implementation is! FeatureOffRepository)
          surface.name,
    ];
    if (rejected.isNotEmpty) {
      throw StateError(
        'Device-only repository is forbidden for '
        '${environment.flavor.name}: ${rejected.join(', ')}',
      );
    }
  }
}
