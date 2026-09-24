import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:movera_rider/core/storage/preferences_store.dart';
import 'package:movera_rider/features/saved_places/domain/saved_place.dart';
import 'package:movera_rider/shared/models/saved_places.dart';

abstract class SavedPlacesStorage {
  Future<String?> read();
  Future<void> write(String json);
}

class PrefsSavedPlacesStorage implements SavedPlacesStorage {
  static const key = 'movera_saved_places_v1';

  @override
  Future<String?> read() async {
    final prefs = await PreferencesStore.load();
    return prefs.getString(key);
  }

  @override
  Future<void> write(String json) async {
    final prefs = await PreferencesStore.load();
    await prefs.setString(key, json);
  }
}

class MemorySavedPlacesStorage implements SavedPlacesStorage {
  MemorySavedPlacesStorage([this.value]);
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String json) async => value = json;
}

class SavedPlacesRepository {
  SavedPlacesRepository({
    List<PlaceShortcut> shortcuts = const [],
    SavedPlacesStorage? storage,
  }) : _shortcuts = List<PlaceShortcut>.of(shortcuts),
       _storage = storage ?? PrefsSavedPlacesStorage();

  final List<PlaceShortcut> _shortcuts;
  final SavedPlacesStorage _storage;
  bool _hydrated = false;

  List<SavedPlacesModel> options() => [
    SavedPlacesModel(title: 'Add Home', icon: Icons.house_rounded),
    SavedPlacesModel(title: 'Add Work', icon: Icons.work_outline_rounded),
    SavedPlacesModel(title: 'Add School', icon: Icons.bookmark_outline_rounded),
    SavedPlacesModel(title: 'Add Gym', icon: Icons.bookmark_outline_rounded),
  ];

  List<PlaceShortcut> shortcuts() => List.unmodifiable(_shortcuts);

  Future<void> hydrate() async {
    if (_hydrated) return;
    _hydrated = true;
    final raw = await _storage.read();
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final restored = <PlaceShortcut>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final title = (map['title'] as String?)?.trim() ?? '';
        final subtitle = (map['subtitle'] as String?)?.trim() ?? '';
        final kind = (map['kind'] as String?)?.trim() ?? '';
        if (title.isEmpty || subtitle.isEmpty || kind.isEmpty) continue;
        restored.add(
          PlaceShortcut(title: title, subtitle: subtitle, kind: kind),
        );
      }
      _shortcuts
        ..clear()
        ..addAll(restored);
    } catch (_) {
      // Corrupt local convenience data must not replace the current session.
    }
  }

  Future<void> save(PlaceShortcut place) async {
    await hydrate();
    final index = _shortcuts.indexWhere(
      (item) => item.kind.toLowerCase() == place.kind.toLowerCase(),
    );
    if (index < 0) {
      _shortcuts.add(place);
    } else {
      _shortcuts[index] = place;
    }
    await _persist();
  }

  Future<void> removeKind(String kind) async {
    await hydrate();
    _shortcuts.removeWhere(
      (item) => item.kind.toLowerCase() == kind.toLowerCase(),
    );
    await _persist();
  }

  Future<void> _persist() => _storage.write(
    jsonEncode(
      _shortcuts
          .map(
            (item) => {
              'title': item.title,
              'subtitle': item.subtitle,
              'kind': item.kind,
            },
          )
          .toList(),
    ),
  );
}
