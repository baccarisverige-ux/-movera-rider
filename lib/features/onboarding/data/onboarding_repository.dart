import 'package:movera_rider/core/storage/preferences_store.dart';

class OnboardingRepository {
  static const _key = 'movera_onboarding_done';

  Future<bool> completed() async {
    final prefs = await PreferencesStore.load();
    return prefs.getBool(_key) ?? true;
  }

  Future<void> markSeen() async {
    final prefs = await PreferencesStore.load();
    await prefs.setBool(_key, true);
  }
}
