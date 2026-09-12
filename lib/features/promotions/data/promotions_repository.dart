import 'package:movera_rider/core/constants/appassets.dart';

class PromoCardData {
  const PromoCardData({required this.background, required this.image});
  final String background;
  final String image;
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
}
