import 'package:movera_rider/core/storage/preferences_store.dart';

class SettingsRepository {
  Future<bool> notificationsEnabled() async {
    final prefs = await PreferencesStore.load();
    return prefs.getBool('movera_notifications') ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await PreferencesStore.load();
    await prefs.setBool('movera_notifications', value);
  }
}
