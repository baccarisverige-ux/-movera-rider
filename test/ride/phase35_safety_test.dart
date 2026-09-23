import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('Safety remote transport uses shared AppScope API', () {
    final s=File('lib/features/safety/data/safety_store.dart').readAsStringSync();
    expect(s, contains('ApiSafetyRemoteDataSource(api ?? AppScope.instance.api)'));
    expect(s, isNot(contains('ApiSafetyRemoteDataSource(ApiClient())')));
  });
  test('Safety store preserves local plus remote boundary', () {
    final s=File('lib/features/safety/data/safety_store.dart').readAsStringSync();
    expect(s, contains('SafetyLocalDataSource'));
    expect(s, contains('SafetyRemoteDataSource'));
  });
}
