/// Central Movera motion timings. Do not hardcode durations in features.
abstract final class MoveraDurations {
  static const micro = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 260);
  static const large = Duration(milliseconds: 360);
  static const sheetOpen = Duration(milliseconds: 380);
  static const sheetClose = Duration(milliseconds: 240);
  static const reduced = Duration(milliseconds: 1);
}
