import 'package:movera_rider/features/settings/data/settings_repository.dart';

class SettingsController {
  SettingsController({SettingsRepository? store})
      : _store = store ?? SettingsRepository();
  final SettingsRepository _store;

  Future<bool> notificationsEnabled() => _store.notificationsEnabled();
  Future<void> setNotificationsEnabled(bool value) =>
      _store.setNotificationsEnabled(value);
}
