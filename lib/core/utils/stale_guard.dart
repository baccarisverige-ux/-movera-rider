/// Drops stale async results after a newer request starts or the owner disposes.
class StaleGuard {
  int _generation = 0;
  bool _disposed = false;

  int next() {
    _generation += 1;
    return _generation;
  }

  bool isCurrent(int generation) => !_disposed && generation == _generation;

  void dispose() => _disposed = true;

  bool get disposed => _disposed;
}
