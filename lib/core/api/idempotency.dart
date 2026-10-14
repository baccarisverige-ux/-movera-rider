import 'dart:convert';

import 'package:movera_rider/core/utils/request_id.dart';

String newIdempotencyKey(String operation) => '$operation-${newRequestId()}';

/// A key derived from [intent] alone: the same intent gives the same key on
/// every call, every controller and every run, so a confirmed mutation that
/// is sent again after a timeout is recognised by the server (ARCH-4).
String stableIdempotencyKey(String operation, String intent) =>
    '$operation-${_fnv1a64(intent)}';

/// FNV-1a 64-bit over UTF-8, in BigInt so web builds get the same value.
String _fnv1a64(String value) {
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask = (BigInt.one << 64) - BigInt.one;
  for (final unit in utf8.encode(value)) {
    hash = ((hash ^ BigInt.from(unit)) * prime) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}
