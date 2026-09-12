import 'package:movera_rider/features/profile/data/profile_repository.dart';

class ProfileController {
  ProfileController({ProfileRepository? store})
      : _store = store ?? ProfileRepository();
  final ProfileRepository _store;

  String displayName() => _store.displayName();
  String referralCode() => _store.referralCode();
}
