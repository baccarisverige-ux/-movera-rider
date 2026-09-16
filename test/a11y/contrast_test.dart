import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/shared/design_system/movera_empty_state.dart';
import 'package:movera_rider/shared/design_system/tokens.dart';

double _linear(double c) {
  return c <= 0.04045
      ? c / 12.92
      : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(Color color) {
  return 0.2126 * _linear(color.r) +
      0.7152 * _linear(color.g) +
      0.0722 * _linear(color.b);
}

double contrastRatio(Color foreground, Color background) {
  final l1 = _luminance(foreground);
  final l2 = _luminance(background);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('muted body grey meets 4.5:1 on white and soft fill', () {
    const muted = Color(0xFF5C656C);
    const white = Color(0xFFFFFFFF);
    const soft = Color(0xFFF1F5F7);
    expect(contrastRatio(muted, white), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(muted, soft), greaterThanOrEqualTo(4.5));
    expect(MoveraTokens.muted, muted);
  });

  test('empty-state muted uses the passing body grey', () {
    const muted = Color(0xFF5C656C);
    final src = File(
      'lib/shared/design_system/movera_empty_state.dart',
    ).readAsStringSync();
    expect(src.contains('0xFF5C656C'), isTrue);
    expect(src.contains('0xFF778189'), isFalse);
    expect(MoveraEmptyState, isNotNull);
    expect(
      contrastRatio(muted, const Color(0xFFF1F5F7)),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('failing muted greys are gone from lib', () {
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final src = file.readAsStringSync();
      expect(src.contains('0xFF778189'), isFalse, reason: file.path);
      expect(src.contains('0xFF7B8388'), isFalse, reason: file.path);
    }
  });
}
