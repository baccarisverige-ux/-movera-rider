import 'package:flutter/foundation.dart';
import 'package:movera_rider/features/profile/data/profile_repository.dart';
import 'package:movera_rider/features/profile/domain/profile.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({ProfileRepository? store})
    : _store = store ?? ProfileRepository();

  final ProfileRepository _store;

  RiderProfileData get profile => _store.current;

  String displayName() => _store.displayName();

  String referralCode() => _store.referralCode();

  Future<void> hydrate() async {
    await _store.hydrate();
    notifyListeners();
  }

  Future<void> update(RiderProfileData next) async {
    await _store.save(next);
    notifyListeners();
  }
}
