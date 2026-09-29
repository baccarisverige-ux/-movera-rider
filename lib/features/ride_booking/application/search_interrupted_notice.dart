/// Set when a live ride search was dropped rather than restored, so Home can
/// say so instead of just appearing empty as though nothing had been going
/// on. A leaf with no imports: Home reads it without depending on
/// RideRestoreCoordinator, which itself depends on Home.
class SearchInterruptedNotice {
  /// The notice RideRestoreCoordinator.instance writes and Home reads.
  static final shared = SearchInterruptedNotice();

  bool _pending = false;

  /// Record that a live ride search was dropped rather than resumed.
  void note() => _pending = true;

  /// Reads the notice and clears it, so the rider is told once.
  bool take() {
    if (!_pending) return false;
    _pending = false;
    return true;
  }
}
