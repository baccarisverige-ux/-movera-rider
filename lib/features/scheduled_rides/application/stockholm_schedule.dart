/// Europe/Stockholm wall-clock pickup rules (CET/CEST, no extra deps).
class StockholmSchedule {
  static const int leadMinutes = 30;
  static const int slotMinutes = 5;

  /// Current wall-clock time in Europe/Stockholm.
  ///
  /// [now] is converted to UTC first so tests can pass `DateTime.utc(...)`.
  static DateTime stockholmNow([DateTime? now]) {
    final utc = (now ?? DateTime.now()).toUtc();
    final local = utc.add(Duration(hours: _cetCestOffsetHours(utc)));
    return DateTime(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
      local.millisecond,
    );
  }

  /// Earliest legal pickup: Stockholm now + [leadMinutes], rounded to 5 min.
  static DateTime minimumPickup([DateTime? now]) {
    return roundToFive(
      stockholmNow(now).add(const Duration(minutes: leadMinutes)),
    );
  }

  /// Default Book later slot (same as [minimumPickup]).
  static DateTime defaultPickup([DateTime? now]) => minimumPickup(now);

  /// Round up to the next 5-minute slot; keep an exact 5-minute wall time.
  static DateTime roundToFive(DateTime dt) {
    final remainder = dt.minute % slotMinutes;
    final shifted = dt.add(
      Duration(minutes: remainder == 0 ? 0 : slotMinutes - remainder),
    );
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
    );
  }

  /// Raise [dt] to [minimumPickup] when it is in the past (or too soon).
  static DateTime clampPickup(DateTime dt, [DateTime? now]) {
    final min = minimumPickup(now);
    if (dt.isBefore(min)) return min;
    return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
  }

  /// Continue-button predicate: pickup must be at/after Stockholm now+30.
  static bool isLegalPickup(DateTime dt, [DateTime? now]) {
    return !dt.isBefore(minimumPickup(now));
  }

  /// Earliest time the time picker may land on for [date].
  static DateTime timePickerMinFor(DateTime date, [DateTime? now]) {
    final min = minimumPickup(now);
    final day = DateTime(date.year, date.month, date.day);
    final minDay = DateTime(min.year, min.month, min.day);
    if (!day.isAfter(minDay)) return min;
    return day;
  }

  /// EU DST: last Sunday of March 01:00 UTC → CEST; last Sunday of October
  /// 01:00 UTC → CET.
  static int _cetCestOffsetHours(DateTime utc) {
    final instant = utc.toUtc();
    final start = _lastSundayUtc(instant.year, 3).add(const Duration(hours: 1));
    final end = _lastSundayUtc(instant.year, 10).add(const Duration(hours: 1));
    if (!instant.isBefore(start) && instant.isBefore(end)) return 2;
    return 1;
  }

  static DateTime _lastSundayUtc(int year, int month) {
    final firstOfNext = month == 12
        ? DateTime.utc(year + 1, 1, 1)
        : DateTime.utc(year, month + 1, 1);
    var day = firstOfNext.subtract(const Duration(days: 1));
    while (day.weekday != DateTime.sunday) {
      day = day.subtract(const Duration(days: 1));
    }
    return DateTime.utc(day.year, day.month, day.day);
  }
}
