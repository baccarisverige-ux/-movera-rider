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
  test('presentation stays behind API and persistence boundaries', () {
    for (final file in _dartFiles('lib/features')
        .where((file) => file.path.contains('/presentation/'))) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains("package:http/http.dart")), reason: file.path);
      expect(source, isNot(contains('ApiClient(')), reason: file.path);
      expect(source, isNot(contains('shared_preferences')), reason: file.path);
    }
  });

  test('domain controllers stay free of presentation imports', () {
    const controllerFiles = <String>[
      'lib/features/booking/application/booking_controller.dart',
      'lib/features/finding_driver/application/finding_driver_controller.dart',
      'lib/features/active_ride/application/active_ride_controller.dart',
      'lib/features/ride_complete/application/ride_complete_controller.dart',
    ];
    for (final path in controllerFiles) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('/presentation/')), reason: path);
      expect(source, isNot(contains('BuildContext')), reason: path);
    }
  });

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
