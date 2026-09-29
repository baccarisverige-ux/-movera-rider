final _postcodeLikeToken = RegExp(r'^\d{3,}(\s?\d{2})?$');

/// Shortens a comma-separated place/address string to its first two
/// meaningful parts, dropping postcode-like numeric tokens (e.g. "123 45").
/// Falls back to the trimmed input when nothing survives the filter.
String shortenPlace(String raw) {
  final clean = raw.trim();
  if (clean.isEmpty) return clean;
  final parts = clean
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .where((part) => !_postcodeLikeToken.hasMatch(part))
      .toList();
  if (parts.isEmpty) return clean;
  if (parts.length == 1) return parts.first;
  return '${parts[0]}, ${parts[1]}';
}
