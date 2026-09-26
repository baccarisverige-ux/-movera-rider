import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _dartFiles(String root) sync* {
  final dir = Directory(root);
  if (!dir.existsSync()) return;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}

void main() {
  

  

  test('final lifecycle certification suites remain present', () {
    const required = <String>[
      'integration_test/global_uat_flow_test.dart',
      'integration_test/pre15_all_lifecycle_paths_test.dart',
      'integration_test/ride_flow_test.dart',
      'test/ride/batch3_phase44_state_races_test.dart',
      'test/ride/batch3_phase45_persistence_test.dart',
      'test/ride/batch3_phase46_location_recovery_test.dart',
      'test/ride/batch3_phase47_geocoding_privacy_test.dart',
      'test/ride/batch3_phase48_receipt_dispute_wiring_test.dart',
      'test/ride/batch3_phase49_scheduled_saved_places_test.dart',
      'test/ride/batch3_phase50_api_auth_update_test.dart',
      'test/web/batch3_phase51_wasm_contract_test.dart',
    ];
    for (final path in required) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}
