abstract class SettingsRepository {
  Future<void> refresh();
}

class LocalSettingsRepository implements SettingsRepository {
  @override
  Future<void> refresh() async {}
}
