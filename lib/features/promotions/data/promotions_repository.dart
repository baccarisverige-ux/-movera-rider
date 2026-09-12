import 'package:movera_rider/core/constants/appassets.dart';

class PromoCardData {
  const PromoCardData({required this.background, required this.image});
  final String background;
  final String image;
}

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
  List<PromoCardData> cards() => const [
        PromoCardData(
          background: AppAssets.promoCard2Bg,
          image: AppAssets.promoCard2Img,
        ),
        PromoCardData(
          background: AppAssets.promoCardBg,
          image: AppAssets.promoCardImg,
        ),
      ];

  HomeCampaign homeCampaign() => const HomeCampaign(
        id: 'next_ride_40_sep_2026',
        title: '40% off your next ride',
        active: true,
      );
}
