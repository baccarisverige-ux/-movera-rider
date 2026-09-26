import 'package:flutter/foundation.dart';
import 'package:movera_rider/features/profile/data/account_security_repository.dart';
import 'package:movera_rider/features/profile/domain/account_security.dart';

class AccountSecurityController extends ChangeNotifier {
  AccountSecurityController({AccountSecurityRepository? repository})
      : _repository = repository ?? AccountSecurityRepository();

  final AccountSecurityRepository _repository;

  AccountSecurityState? state;
  bool loading = false;
  bool available = true;
  String? errorMessage;

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      state = await _repository.load();
      available = true;
    } catch (_) {
      state = null;
      available = false;
      errorMessage = 'Account security is unavailable right now.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signOutOtherDevices() async {
    final current = state;
    if (current == null ||
        !available ||
        !current.capabilities.signOutOtherDevices ||
        !current.capabilities.reauthentication) {
      return;
    }
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      state = await _repository.signOutOtherDevices();
      available = true;
    } catch (_) {
      errorMessage = 'Could not update active sessions.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
