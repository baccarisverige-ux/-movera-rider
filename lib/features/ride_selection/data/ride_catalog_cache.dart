import 'dart:convert';

import 'package:movera_rider/core/storage/preferences_store.dart';

/// Last good ride-type list from the server, kept as the raw JSON rows so
/// the one mapper in `RideCatalogController` applies to both sources.
abstract class RideCatalogCache {
  Future<List<Map<String, dynamic>>?> read();
  Future<void> write(List<Map<String, dynamic>> rows);
}

class PrefsRideCatalogCache implements RideCatalogCache {
  const PrefsRideCatalogCache();

  static const key = 'movera_ride_catalog_v1';

  @override
  Future<List<Map<String, dynamic>>?> read() async {
    final prefs = await PreferencesStore.load();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;
    return decoded
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<void> write(List<Map<String, dynamic>> rows) async {
    final prefs = await PreferencesStore.load();
    await prefs.setString(key, jsonEncode(rows));
  }
}

class MemoryRideCatalogCache implements RideCatalogCache {
  MemoryRideCatalogCache([this.rows]);

  List<Map<String, dynamic>>? rows;

  @override
  Future<List<Map<String, dynamic>>?> read() async => rows;

  @override
  Future<void> write(List<Map<String, dynamic>> rows) async {
    this.rows = rows;
  }
}
