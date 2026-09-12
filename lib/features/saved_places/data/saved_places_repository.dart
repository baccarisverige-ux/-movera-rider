import 'package:flutter/material.dart';
import 'package:movera_rider/features/saved_places/domain/saved_place.dart';
import 'package:movera_rider/shared/models/saved_places.dart';

class SavedPlacesRepository {
  List<SavedPlacesModel> options() => [
        SavedPlacesModel(title: 'Add Home', icon: Icons.house_rounded),
        SavedPlacesModel(title: 'Add Work', icon: Icons.work_outline_rounded),
        SavedPlacesModel(title: 'Add School', icon: Icons.bookmark_outline_rounded),
        SavedPlacesModel(title: 'Add Gym', icon: Icons.bookmark_outline_rounded),
      ];

  List<PlaceShortcut> shortcuts() => const [
        PlaceShortcut(
          title: 'Home',
          subtitle: '3.5km| Dubai hotel...',
          kind: 'home',
        ),
        PlaceShortcut(
          title: 'Office',
          subtitle: '5.1km| Sharjah mall...',
          kind: 'office',
        ),
      ];
}
