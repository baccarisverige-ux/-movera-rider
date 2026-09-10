from pathlib import Path

path = Path('lib/features/rider/home/home.dart')
source = path.read_text()

start_marker = '  Widget _comfortRideCarousel() {'
end_marker = 'Widget _homePromoCard({'

start = source.index(start_marker)
end = source.index(end_marker, start)

replacement = '''  Widget _comfortRideCarousel() {
    final viewportWidth = MediaQuery.of(context).size.width;
    final cardWidth = (viewportWidth * 0.78).clamp(270.0, 330.0).toDouble();
    final imageHeight = ResSize.h * 112;
    final bandHeight = ResSize.h * 64;

    return SizedBox(
      height: imageHeight + bandHeight + ResSize.h * 2,
      width: double.infinity,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(right: ResSize.w * 8),
        children: [
          _homePromoCard(
            cardWidth: cardWidth,
            imageHeight: imageHeight,
            bandHeight: bandHeight,
            imageAsset: 'assets/images/movera_comfort_ride.jpeg',
            title: 'Movera Comfort',
            subtitle: 'Extra space. Elevated comfort. A smoother way to ride.',
            onTap: _handleDestinationTap,
          ),
          SizedBox(width: ResSize.w * 12),
          _homePromoCard(
            cardWidth: cardWidth,
            imageHeight: imageHeight,
            bandHeight: bandHeight,
            imageAsset: 'assets/images/pin_verification.png',
            title: 'Safety Toolkit',
            subtitle: 'Essential safety tools, ready throughout every ride.',
            onTap: () {},
          ),
          SizedBox(width: ResSize.w * 12),
          _homePromoCard(
            cardWidth: cardWidth,
            imageHeight: imageHeight,
            bandHeight: bandHeight,
            imageAsset: 'assets/images/airport_rides.png',
            title: 'Fly with ease',
            subtitle: 'Reserve your airport ride ahead and travel with less stress.',
            onTap: _openSchedule,
          ),
          SizedBox(width: ResSize.w * 12),
          _homePromoCard(
            cardWidth: cardWidth,
            imageHeight: imageHeight,
            bandHeight: bandHeight,
            imageAsset: 'assets/images/city_tour.png',
            title: 'Reserve for events',
            subtitle: 'Plan your ride early and arrive exactly when you need to.',
            onTap: _openSchedule,
          ),
          SizedBox(width: ResSize.w * 12),
          _homePromoCard(
            cardWidth: cardWidth,
            imageHeight: imageHeight,
            bandHeight: bandHeight,
            imageAsset: 'assets/images/ride_business.png',
            title: 'Reserve work rides',
            subtitle: 'Reliable scheduled rides for meetings and important workdays.',
            onTap: _openSchedule,
          ),
          SizedBox(width: ResSize.w * 12),
          _homePromoCard(
            cardWidth: cardWidth,
            imageHeight: imageHeight,
            bandHeight: bandHeight,
            imageAsset: 'assets/images/advance_booking_driver.png',
            title: 'Plan for outings',
            subtitle: 'Book ahead for dinners, appointments and plans around town.',
            onTap: _openSchedule,
          ),
          SizedBox(width: ResSize.w * 18),
        ],
      ),
    );
  }

'''

updated = source[:start] + replacement + source[end:]
if updated == source:
    print('No changes needed')
else:
    path.write_text(updated)
    print('Extended only the existing home promo carousel')
