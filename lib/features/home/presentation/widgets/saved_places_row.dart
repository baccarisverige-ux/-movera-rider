import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/home/application/home_places_controller.dart';
import 'package:movera_rider/features/home/presentation/widgets/short_address.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

/// The horizontally-scrolling Home / Work / Add / custom-place row.
class SavedPlacesRow extends StatelessWidget {
  const SavedPlacesRow({
    super.key,
    required this.homeAddress,
    required this.workAddress,
    required this.savedPlaces,
    required this.onUseSavedPlace,
    required this.onAddPlace,
  });

  final String? homeAddress;
  final String? workAddress;
  final List<SavedPlaceData> savedPlaces;
  final void Function(
    String? address, {
    required String target,
    String? customType,
  })
  onUseSavedPlace;
  final VoidCallback onAddPlace;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      SizedBox(
        width: ResSize.w * 108,
        child: _QuickPlaceCard(
          iconAsset: AppAssets.quickHome,
          title: 'Home',
          subtitle: shortAddress(homeAddress, maxLength: 15),
          onTap: () => onUseSavedPlace(homeAddress, target: 'home'),
        ),
      ),
      8.width,
      SizedBox(
        width: ResSize.w * 108,
        child: _QuickPlaceCard(
          iconAsset: AppAssets.quickWork,
          title: 'Work',
          subtitle: shortAddress(workAddress, maxLength: 15),
          onTap: () => onUseSavedPlace(workAddress, target: 'work'),
        ),
      ),
      8.width,
      SizedBox(
        width: ResSize.w * 108,
        child: _QuickPlaceCard(
          iconAsset: AppAssets.quickAdd,
          title: 'Add',
          subtitle: 'New place',
          onTap: onAddPlace,
        ),
      ),
    ];
    for (final place in savedPlaces) {
      cards
        ..add(8.width)
        ..add(
          SizedBox(
            width: ResSize.w * 108,
            child: _CustomPlaceCard(
              place: place,
              onTap: () => onUseSavedPlace(
                place.address,
                target: 'custom',
                customType: place.type,
              ),
            ),
          ),
        );
    }
    return SizedBox(
      height: ResSize.h * 46,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(children: cards),
      ),
    );
  }
}

String _placeLabel(String type) {
  switch (type) {
    case 'gym':
      return 'Gym';
    case 'mall':
      return 'Mall';
    case 'school':
      return 'School';
    case 'airport':
      return 'Airport';
    case 'family':
      return 'Family';
    case 'restaurant':
      return 'Restaurant';
    default:
      return 'Other';
  }
}

IconData _placeIcon(String type) {
  switch (type) {
    case 'gym':
      return Icons.fitness_center_rounded;
    case 'mall':
      return Icons.local_mall_outlined;
    case 'school':
      return Icons.school_outlined;
    case 'airport':
      return Icons.flight_takeoff_rounded;
    case 'family':
      return Icons.family_restroom_rounded;
    case 'restaurant':
      return Icons.restaurant_rounded;
    default:
      return Icons.place_outlined;
  }
}

class _CustomPlaceCard extends StatelessWidget {
  const _CustomPlaceCard({required this.place, required this.onTap});

  static const Color _premiumInk = Color(0xFF1D252C);
  static const Color _premiumMuted = Color(0xFF5C656C);
  static const Color _premiumAccent = Color(0xFF2D5878);

  final SavedPlaceData place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: ResSize.h * 44,
          padding: EdgeInsets.symmetric(horizontal: ResSize.w * 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF5F9F9)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDDE7E9), width: 0.8),
          ),
          child: Row(
            children: [
              Icon(
                _placeIcon(place.type),
                size: ResSize.h * 13,
                color: _premiumAccent,
              ),
              7.width,
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: _placeLabel(place.type),
                      color: _premiumInk,
                      fontSize: 10.5,
                      fontWeight: fwSemiBold,
                    ),
                    2.height,
                    TextWidget(
                      text: shortAddress(place.address, maxLength: 15),
                      color: _premiumMuted.withValues(alpha: 0.82),
                      fontSize: 7.8,
                      fontWeight: fwNormal,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickPlaceCard extends StatelessWidget {
  const _QuickPlaceCard({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  static const Color _premiumInk = Color(0xFF1D252C);
  static const Color _premiumMuted = Color(0xFF5C656C);

  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: ResSize.h * 44,
          padding: EdgeInsets.symmetric(horizontal: ResSize.w * 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF5F9F9)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDDE7E9), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF174E55).withValues(alpha: 0.055),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppColor.white.withValues(alpha: 0.9),
                blurRadius: 2,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(
                excludeFromSemantics: true,
                iconAsset,
                height: ResSize.h * 12.3,
                width: ResSize.w * 12.3,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              8.width,
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: title,
                      color: _premiumInk,
                      fontSize: 11.5,
                      fontWeight: fwSemiBold,
                    ),
                    2.height,
                    TextWidget(
                      text: subtitle,
                      color: _premiumMuted.withValues(alpha: 0.82),
                      fontSize: 8.25,
                      fontWeight: fwNormal,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
