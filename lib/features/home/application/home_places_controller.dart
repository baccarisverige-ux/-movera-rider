import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/features/home/data/home_repository.dart';

class SavedPlaceData {
  const SavedPlaceData({
    required this.title,
    required this.type,
    required this.address,
  });

  final String title;
  final String type;
  final String address;

  Map<String, String> toJson() => {
    'title': title,
    'type': type,
    'address': address,
  };

  factory SavedPlaceData.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'other';
    return SavedPlaceData(
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : type,
      type: type,
      address: json['address'] as String? ?? '',
    );
  }
}

/// Owns saved/recent/home/work/pickup/destination/stops and trip pickup.
/// Home presentation only paints.
class HomePlacesController {
  HomePlacesController({HomeAddressRepository? store})
      : _store = store ?? HomeAddressRepository();

  final HomeAddressRepository _store;

  Stream<void> get changes => _store.changes;

  static const maxRecent = 8;
  static const maxCustom = 8;

  String? pickupAddress;
  String? destinationAddress;
  String? homeAddress;
  String? workAddress;
  List<String> routeStops = [];
  List<String> recentAddresses = [];
  List<SavedPlaceData> savedPlaces = [];
  LatLng? currentLatLng;
  LatLng? tripPickupLatLng;

  Future<void> load() async {
    final saved = await _store.load();
    homeAddress = saved.home;
    workAddress = saved.work;
    recentAddresses = List<String>.from(saved.recent);
    savedPlaces = saved.places
        .map((place) => SavedPlaceData.fromJson(Map<String, dynamic>.from(place)))
        .take(maxCustom)
        .toList();
  }

  Future<void> persist() {
    return _store.save(
      HomeAddressSnapshot(
        home: homeAddress,
        work: workAddress,
        recent: recentAddresses,
        places: savedPlaces.map((place) => place.toJson()).toList(),
      ),
    );
  }

  void remember(String address) {
    final clean = address.trim();
    if (clean.isEmpty || clean == 'Current location') return;
    recentAddresses.removeWhere(
      (saved) => saved.toLowerCase() == clean.toLowerCase(),
    );
    recentAddresses.insert(0, clean);
    if (recentAddresses.length > maxRecent) {
      recentAddresses = recentAddresses.take(maxRecent).toList();
    }
  }

  String? existingFor(String target) {
    switch (target) {
      case 'pickup':
        return pickupAddress;
      case 'home':
        return homeAddress;
      case 'work':
        return workAddress;
      case 'destination':
        return destinationAddress;
      default:
        return null;
    }
  }

  void applyResolved({
    required String target,
    required String address,
    LatLng? pickupPosition,
    String? customType,
  }) {
    switch (target) {
      case 'pickup':
        pickupAddress = address;
        tripPickupLatLng = pickupPosition;
        break;
      case 'destination':
        destinationAddress = address;
        break;
      case 'home':
        homeAddress = address;
        break;
      case 'work':
        workAddress = address;
        break;
      case 'custom':
        final type = customType ?? 'other';
        final existingIndex = savedPlaces.indexWhere((place) => place.type == type);
        final place = SavedPlaceData(title: type, type: type, address: address);
        if (existingIndex >= 0) {
          savedPlaces[existingIndex] = place;
        } else if (savedPlaces.length < maxCustom) {
          savedPlaces.add(place);
        }
        break;
    }
    remember(address);
  }
}
