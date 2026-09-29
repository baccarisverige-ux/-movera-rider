class AppUpdatePolicy {
  const AppUpdatePolicy({
    required this.minimumBuild,
    required this.currentBuild,
  });

  final int minimumBuild;
  final int currentBuild;

  bool get requiresUpdate => currentBuild < minimumBuild;

  factory AppUpdatePolicy.fromConfig(
    Map<String, dynamic> config, {
    required int currentBuild,
  }) {
    final raw = config['minimumBuild'];
    final minimum = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    return AppUpdatePolicy(
      minimumBuild: minimum == null || minimum < 0 ? 0 : minimum,
      currentBuild: currentBuild,
    );
  }
}
