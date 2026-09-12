import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  Iterable<File> presentation() => Directory('lib/features')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.contains('/presentation/') && f.path.endsWith('.dart'));

  test('presentation does not import raw http or shared_preferences', () {
    for (final file in presentation()) {
      final src = file.readAsStringSync();
      expect(src.contains("package:http/http.dart"), isFalse, reason: file.path);
      expect(
        src.contains("package:shared_preferences/shared_preferences.dart"),
        isFalse,
        reason: file.path,
      );
      expect(src.contains('sk_live'), isFalse, reason: file.path);
      expect(src.contains("package:movera_rider/core/api/api_client.dart"), isFalse,
          reason: file.path);
    }
  });

  test('no SharedPreferences token storage', () {
    final token = File('lib/core/auth/token_store.dart').readAsStringSync();
    expect(token.contains("package:shared_preferences"), isFalse);
    final secure = File('lib/core/auth/secure_token_store.dart').readAsStringSync();
    expect(secure.contains("package:shared_preferences"), isFalse);
  });

  test('finding driver assignment is not a widget Timer', () {
    final ui = File(
      'lib/features/finding_driver/presentation/finding_drivers.dart',
    ).readAsStringSync();
    expect(ui.contains('Timer(Duration(seconds: 12)'), isFalse);
  });

  test('home does not own ride restoration', () {
    final home = File('lib/features/home/presentation/home.dart').readAsStringSync();
    expect(home.contains('_restoreActiveRide'), isFalse);
    expect(home.contains('RideSnapshotStore'), isFalse);
  });

  test('presentation has no catalog fare table', () {
    for (final file in presentation()) {
      final src = file.readAsStringSync();
      expect(src.contains("'movera': 259"), isFalse, reason: file.path);
    }
  });
}
