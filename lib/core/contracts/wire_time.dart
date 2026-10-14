/// Timestamps on the wire are RFC 3339 in UTC with an explicit offset
/// (ARCH-11). These two helpers are the only conversion points.
abstract final class WireTime {
  /// `2026-10-14T08:30:00.000Z`, never a local time without an offset.
  static String format(DateTime time) => time.toUtc().toIso8601String();

  /// Parses an RFC 3339 string into a UTC [DateTime]. A legacy value without
  /// an offset is read as device-local (Dart's rule) and then normalised.
  static DateTime? tryParse(Object? raw) =>
      raw is String ? DateTime.tryParse(raw.trim())?.toUtc() : null;

  /// The device clock, in UTC, for client-side stamps.
  static DateTime now() => DateTime.now().toUtc();
}
