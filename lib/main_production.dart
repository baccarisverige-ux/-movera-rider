import 'package:movera_rider/app/bootstrap.dart';
import 'package:movera_rider/app/config/env.dart';

void main() {
  if (AppEnv.current.flavor != AppFlavor.production) {
    throw StateError(
      'This entrypoint requires MOVERA_FLAVOR=production; '
      'got ${AppEnv.current.flavor.name}.',
    );
  }
  bootstrap();
}
