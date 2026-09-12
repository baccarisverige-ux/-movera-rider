import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive settings only. Tokens never go here.
class PreferencesStore {
  PreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  Future<void> setString(String key, String value) => _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);
  Future<void> setDouble(String key, double value) => _prefs.setDouble(key, value);
  double? getDouble(String key) => _prefs.getDouble(key);
  Future<void> remove(String key) => _prefs.remove(key);
}
