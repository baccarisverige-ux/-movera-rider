import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/api/api_client.dart';

/// What the backend said about an account deletion request.
class AccountDeletionRequest {
  const AccountDeletionRequest({required this.status});

  /// `scheduled`: the backend accepted the request and erases the account
  /// on its own schedule (legal retention, open payments).
  final String status;
}

class AccountRepository {
  AccountRepository({ApiClient? api}) : _api = api ?? AppScope.instance.api;

  final ApiClient _api;

  /// Asks the backend to delete this rider's account (`POST
  /// /api/v1/account/deletion`, 202 `{status: "scheduled"}`). Throws when
  /// the request was not accepted, so the screen never claims it was sent.
  Future<AccountDeletionRequest> requestDeletion() async {
    final response = await _api.post('/api/v1/account/deletion');
    final status = response['status'];
    if (status is! String || status.trim().isEmpty) {
      throw StateError('Account deletion response was incomplete.');
    }
    return AccountDeletionRequest(status: status.trim());
  }
}
