abstract class AuthRepository {
  Future<void> refresh();
}

class LocalAuthRepository implements AuthRepository {
  @override
  Future<void> refresh() async {}
}
