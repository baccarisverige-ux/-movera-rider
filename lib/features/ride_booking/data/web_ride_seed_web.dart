import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';

void registerWebQaHooks() {
  globalContext.setProperty(
    'moveraSeedActiveRide'.toJS,
    ((JSString raw) {
      return _seed(raw.toDart).toJS;
    }).toJS,
  );
}

Future<JSString> _seed(String raw) async {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return 'bad'.toJS;
    final snapshot = RideSnapshot.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    if (snapshot == null) return 'invalid'.toJS;
    await RideSnapshotStore.save(snapshot);
    return 'ok'.toJS;
  } catch (_) {
    return 'error'.toJS;
  }
}
