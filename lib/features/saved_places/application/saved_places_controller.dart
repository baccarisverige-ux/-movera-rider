import 'package:flutter/material.dart';
import 'package:movera_rider/features/home/data/home_repository.dart';
import 'package:movera_rider/features/saved_places/domain/saved_place.dart';
import 'package:movera_rider/shared/models/saved_places.dart';

class SavedPlacesController {
  SavedPlacesController({HomeAddressRepository? store})
      : _store = store ?? HomeAddressRepository();

  final HomeAddressRepository _store;
  final List<PlaceShortcut> _shortcuts = <PlaceShortcut>[];

  List<SavedPlacesModel> options() => [
    SavedPlacesModel(title: 'Add Home', icon: Icons.house_rounded),
    SavedPlacesModel(title: 'Add Work', icon: Icons.work_outline_rounded),
    SavedPlacesModel(title: 'Add School', icon: Icons.bookmark_outline_rounded),
    SavedPlacesModel(title: 'Add Gym', icon: Icons.bookmark_outline_rounded),
  ];

  List<PlaceShortcut> shortcuts() =>
      List<PlaceShortcut>.unmodifiable(_shortcuts);

  Stream<void> get changes => _store.changes;

  Future<void> hydrate() async {
    final snapshot = await _store.load();
    _shortcuts
      ..clear()
      ..addAll(_fromSnapshot(snapshot));
  }

  Future<void> save(PlaceShortcut place) async {
    final clean = PlaceShortcut(
      title: place.title.trim(),
      subtitle: place.subtitle.trim(),
      kind: _normalizeKind(place.kind),
    );
    if (clean.title.isEmpty || clean.subtitle.isEmpty) {
      throw ArgumentError('Saved place requires both a name and a location.');
    }

    final snapshot = await _store.load();
    final places = snapshot.places
        .map((item) => Map<String, String>.from(item))
        .toList();

    String? home = snapshot.home;
    String? work = snapshot.work;
    if (clean.kind == 'home') {
      home = clean.subtitle;
    } else if (clean.kind == 'office') {
      work = clean.subtitle;
    } else {
      final index = places.indexWhere(
        (item) => _normalizeKind(item['type'] ?? '') == clean.kind,
      );
      final encoded = <String, String>{
        'title': clean.title,
        'type': clean.kind,
        'address': clean.subtitle,
      };
      if (index < 0) {
        places.add(encoded);
      } else {
        places[index] = encoded;
      }
    }

    await _store.save(
      HomeAddressSnapshot(
        home: home,
        work: work,
        recent: snapshot.recent,
        places: places,
      ),
    );
    await hydrate();
  }

  Future<void> removeKind(String kind) async {
    final normalized = _normalizeKind(kind);
    final snapshot = await _store.load();
    final places = snapshot.places
        .map((item) => Map<String, String>.from(item))
        .where(
          (item) => _normalizeKind(item['type'] ?? '') != normalized,
        )
        .toList();

    await _store.save(
      HomeAddressSnapshot(
        home: normalized == 'home' ? null : snapshot.home,
        work: normalized == 'office' ? null : snapshot.work,
        recent: snapshot.recent,
        places: places,
      ),
    );
    await hydrate();
  }

  List<PlaceShortcut> _fromSnapshot(HomeAddressSnapshot snapshot) {
    final result = <PlaceShortcut>[];
    final home = snapshot.home?.trim();
    if (home?.isNotEmpty == true) {
      result.add(PlaceShortcut(title: 'Home', subtitle: home!, kind: 'home'));
    }
    final work = snapshot.work?.trim();
    if (work?.isNotEmpty == true) {
      result.add(PlaceShortcut(title: 'Work', subtitle: work!, kind: 'office'));
    }
    for (final item in snapshot.places) {
      final address = (item['address'] ?? '').trim();
      if (address.isEmpty) continue;
      final kind = _normalizeKind(item['type'] ?? 'other');
      final title = (item['title'] ?? '').trim();
      result.add(
        PlaceShortcut(
          title: title.isEmpty ? _labelForKind(kind) : title,
          subtitle: address,
          kind: kind,
        ),
      );
    }
    return result;
  }

  String _normalizeKind(String value) {
    final lower = value.trim().toLowerCase();
    if (lower == 'work') return 'office';
    if (lower.isEmpty) return 'other';
    return lower;
  }

  String _labelForKind(String kind) {
    if (kind == 'office') return 'Work';
    if (kind == 'home') return 'Home';
    return kind
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
