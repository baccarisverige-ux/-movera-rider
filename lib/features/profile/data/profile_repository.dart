abstract class ProfileRepository {
  Future<void> refresh();
}

class LocalProfileRepository implements ProfileRepository {
  @override
  Future<void> refresh() async {}
}
