import 'dart:math';

String newRequestId() {
  final rand = Random.secure();
  final bytes = List<int>.generate(12, (_) => rand.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
