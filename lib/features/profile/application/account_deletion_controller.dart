import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/auth/application/auth_controller.dart';
import 'package:movera_rider/features/profile/data/account_repository.dart';

/// Delete account (FLOW-2): asks the backend to delete the account, then
/// ends the session and wipes this device like Sign out does.
class AccountDeletionController {
  AccountDeletionController({
    AccountRepository? repository,
    AuthController? auth,
  }) : _repository = repository ?? AccountRepository(),
       _auth = auth ?? AppScope.instance.auth;

  final AccountRepository _repository;
  final AuthController _auth;

  /// Throws when the backend did not accept the request; nothing is wiped
  /// then, so the rider can try again.
  Future<void> requestDeletion() async {
    await _repository.requestDeletion();
    await _auth.signOutLocally();
  }
}
