/// Truncates an address for compact display, matching home.dart's own
/// `_shortAddress` formatting exactly.
String shortAddress(String? address, {int maxLength = 24}) {
  final value = address?.trim() ?? '';
  if (value.isEmpty) return 'Set location';
  return value.length <= maxLength
      ? value
      : '${value.substring(0, maxLength - 1)}…';
}
