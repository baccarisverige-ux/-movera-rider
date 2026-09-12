import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/auth/secure_token_store.dart';
import 'package:movera_rider/core/auth/token_store.dart';

void main() {
  test('memory override roundtrip', () async {
    final store = SecureTokenStore(override: MemoryTokenStore());
    await store.save(access: 'a', refresh: 'r');
    expect(await store.readAccess(), 'a');
    expect(await store.readRefresh(), 'r');
    await store.clear();
    expect(await store.readAccess(), isNull);
  });
}
