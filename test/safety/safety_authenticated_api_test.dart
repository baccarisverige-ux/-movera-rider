import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SafetyStore never constructs an unauthenticated ApiClient', () {
    final source = File(
      'lib/features/safety/data/safety_store.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('ApiSafetyRemoteDataSource(ApiClient())')));
    expect(
      source,
      contains('ApiSafetyRemoteDataSource(api ?? AppScope.instance.api)'),
    );
  });
}
