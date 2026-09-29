import 'package:movera_rider/app/bootstrap.dart';
import 'package:movera_rider/app/config/env.dart';

void main() {
  if (AppEnv.current.flavor != AppFlavor.staging) {
    throw StateError(
      'This entrypoint requires MOVERA_FLAVOR=staging; '
      'got ${AppEnv.current.flavor.name}.',
    );
  }
  bootstrap();
}
