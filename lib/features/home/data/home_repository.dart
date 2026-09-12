import 'dart:convert';

import 'package:movera_rider/core/storage/preferences_store.dart';

class HomeAddressSnapshot {
  HomeAddressSnapshot({
    this.home,
    this.work,
    this.recent = const [],
    this.places = const [],
  });

  final String? home;
  final String? work;
  final List<String> recent;
  final List<Map<String, String>> places;
}

class HomeAddressRepository {
  Future<HomeAddressSnapshot> load() async {
    final prefs = await PreferencesStore.load();
    final places = <Map<String, String>>[];
    final raw = prefs.getString('movera_saved_places');
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map) {
            final map = item.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            );
            if ((map['address'] ?? '').trim().isNotEmpty) places.add(map);
          }
        }
      } catch (_) {}
    }
    return HomeAddressSnapshot(
      home: prefs.getString('movera_home_address'),
      work: prefs.getString('movera_work_address'),
      recent: prefs.getStringList('movera_recent_addresses') ?? <String>[],
      places: places,
    );
  }

  Future<void> save(HomeAddressSnapshot data) async {
    final prefs = await PreferencesStore.load();
    if (data.home == null) {
      await prefs.remove('movera_home_address');
    } else {
      await prefs.setString('movera_home_address', data.home!);
    }
    if (data.work == null) {
      await prefs.remove('movera_work_address');
    } else {
      await prefs.setString('movera_work_address', data.work!);
    }
    await prefs.setStringList('movera_recent_addresses', data.recent);
    await prefs.setString('movera_saved_places', jsonEncode(data.places));
  }
}
