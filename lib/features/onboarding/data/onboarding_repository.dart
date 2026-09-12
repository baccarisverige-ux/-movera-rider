abstract class OnboardingRepository {
  Future<void> refresh();
}

class LocalOnboardingRepository implements OnboardingRepository {
  @override
  Future<void> refresh() async {}
}
