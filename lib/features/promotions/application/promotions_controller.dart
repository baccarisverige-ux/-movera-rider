import 'package:movera_rider/features/promotions/data/promotions_repository.dart';

class PromotionsController {
  PromotionsController({PromotionsRepository? store})
      : _store = store ?? PromotionsRepository();
  final PromotionsRepository _store;

  List<PromoCardData> cards() => _store.cards();
}
