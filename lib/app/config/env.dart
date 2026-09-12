enum AppFlavor { dev, staging, production }

class AppEnv {
  const AppEnv({
    required this.flavor,
    required this.apiBaseUrl,
    required this.mapsEnabled,
  });

  final AppFlavor flavor;
  final String apiBaseUrl;
  final bool mapsEnabled;

  static const current = AppEnv(
    flavor: AppFlavor.dev,
    apiBaseUrl: 'https://api.dev.movera.invalid',
    mapsEnabled: true,
  );

  bool get isProduction => flavor == AppFlavor.production;
}
