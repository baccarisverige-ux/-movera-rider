import 'package:flutter/material.dart';
import 'package:movera_rider/shared/models/saved_places.dart';

class SavedPlacesRepository {
  List<SavedPlacesModel> options() => [
        SavedPlacesModel(title: 'Add Home', icon: Icons.house_rounded),
        SavedPlacesModel(title: 'Add Work', icon: Icons.work_outline_rounded),
        SavedPlacesModel(title: 'Add School', icon: Icons.bookmark_outline_rounded),
        SavedPlacesModel(title: 'Add Gym', icon: Icons.bookmark_outline_rounded),
      ];
}
