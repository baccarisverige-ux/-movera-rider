import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presentation does not import raw http or shared_preferences', () {
    final files = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.contains('/presentation/') && f.path.endsWith('.dart'));
    for (final file in files) {
      final src = file.readAsStringSync();
      expect(
        src.contains("package:http/http.dart"),
        isFalse,
        reason: file.path,
      );
      expect(
        src.contains("package:shared_preferences/shared_preferences.dart"),
        isFalse,
        reason: file.path,
      );
      expect(src.contains('sk_live'), isFalse, reason: file.path);
      expect(src.contains('sk_test'), isFalse, reason: file.path);
    }
  });

  test('no SharedPreferences token storage', () {
    final token = File('lib/core/auth/token_store.dart').readAsStringSync();
    expect(token.contains('SharedPreferences'), isFalse);
    final secure = File('lib/core/auth/secure_token_store.dart').readAsStringSync();
    expect(secure.contains('SharedPreferences'), isFalse);
  });

  test('finding driver assignment is not a widget Timer', () {
    final ui = File(
      'lib/features/finding_driver/presentation/finding_drivers.dart',
    ).readAsStringSync();
    expect(ui.contains('Timer(Duration(seconds: 12)'), isFalse);
  });
}
