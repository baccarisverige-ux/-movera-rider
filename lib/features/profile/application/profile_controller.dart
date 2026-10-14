import 'package:flutter/foundation.dart';
import 'package:movera_rider/features/profile/data/profile_repository.dart';
import 'package:movera_rider/features/profile/domain/profile.dart';
import 'package:movera_rider/features/profile/domain/rider_profile_repository.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({RiderProfileRepository? store})
    : _store = store ?? ProfileRepository();

  final RiderProfileRepository _store;

  /// The repository behind this controller, for the composition guard.
  RiderProfileRepository get repository => _store;

  RiderProfileData get profile => _store.current;

  String displayName() => _store.displayName();

  Future<void> hydrate() async {
    await _store.hydrate();
    notifyListeners();
  }

  /// Drops the in-memory profile at the end of a rider's session.
  void clearLocal() {
    _store.clearLocal();
    notifyListeners();
  }

  Future<void> update(RiderProfileData next) async {
    await _store.save(next);
    notifyListeners();
  }
}
