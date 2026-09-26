enum AppFlavor { demo, dev, test, staging, production }

class AppEnv {
  const AppEnv({
    required this.flavor,
    required this.apiBaseUrl,
    required this.mapsEnabled,
    this.authRequired = false,
  });

  final AppFlavor flavor;
  final String apiBaseUrl;
  final bool mapsEnabled;
  final bool authRequired;

  static const _flavorName = String.fromEnvironment(
    'MOVERA_FLAVOR',
    defaultValue: 'demo',
  );

  static const current = AppEnv(
    flavor: _flavorName == 'production'
        ? AppFlavor.production
        : _flavorName == 'staging'
        ? AppFlavor.staging
        : _flavorName == 'test'
        ? AppFlavor.test
        : _flavorName == 'dev'
        ? AppFlavor.dev
        : AppFlavor.demo,
    apiBaseUrl: String.fromEnvironment(
      'MOVERA_API_BASE_URL',
      defaultValue: 'https://api.demo.movera.invalid',
    ),
    mapsEnabled: bool.fromEnvironment(
      'MOVERA_MAPS_ENABLED',
      defaultValue: true,
    ),
    authRequired: bool.fromEnvironment(
      'MOVERA_AUTH_REQUIRED',
      defaultValue: false,
    ),
  );

  static AppFlavor parseFlavor(String value) {
    return AppFlavor.values.firstWhere(
      (flavor) => flavor.name == value.trim().toLowerCase(),
      orElse: () => AppFlavor.demo,
    );
  }

  bool get isProduction => flavor == AppFlavor.production;
  bool get isReleaseLike =>
      flavor == AppFlavor.staging || flavor == AppFlavor.production;

  bool get allowsMockTransport =>
      flavor == AppFlavor.demo ||
      flavor == AppFlavor.dev ||
      flavor == AppFlavor.test;
}
