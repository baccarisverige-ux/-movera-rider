import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('performance budgets remain explicit', () {
    final s=File('lib/core/performance/performance_budgets.dart').readAsStringSync();
    expect(s, contains('quoteConcurrencyCeiling = 3'));
    expect(s, contains('markerMinimumMoveMeters = 1.5'));
    expect(s, contains('markerMinimumHeadingDegrees = 3'));
  });
  test('home keeps accessibility navigation contracts', () {
    final s=File('lib/features/home/presentation/home.dart').readAsStringSync();
    expect(s, contains('accessibleNavigation'));
    expect(s, contains('FocusTraversalGroup'));
    expect(s, contains('Recenter map on your location'));
  });
}
