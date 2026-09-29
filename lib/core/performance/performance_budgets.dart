abstract final class PerformanceBudgets {
  static const int quoteParallelism = 3;
  static const Duration quoteTimeout = Duration(seconds: 8);

  static const double markerMinimumMoveMeters = 1.5;
  static const double markerMinimumHeadingDegrees = 3;

  /// Maximum number of ride categories allowed to be fetching at once.
  static const int quoteConcurrencyCeiling = 3;
}
