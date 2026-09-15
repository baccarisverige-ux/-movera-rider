class HomeCampaign {
  const HomeCampaign({
    required this.id,
    required this.title,
    required this.active,
  });
  final String id;
  final String title;
  final bool active;
}

class PromotionsRepository {
  /// Campaign data must come from the promotions service. Until that adapter
  /// is connected, an absent campaign is represented honestly as null.
  HomeCampaign? homeCampaign() => null;
}
