import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/saved_places/application/saved_places_controller.dart';
import 'package:movera_rider/features/saved_places/domain/saved_place.dart';
import 'package:movera_rider/features/saved_places/presentation/add_place.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/custom_textfield.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class RiderSearchPickupLocation extends StatefulWidget {
  const RiderSearchPickupLocation({super.key, this.places});

  final SavedPlacesController? places;

  @override
  State<RiderSearchPickupLocation> createState() =>
      _RiderSearchPickupLocationState();
}

class _RiderSearchPickupLocationState extends State<RiderSearchPickupLocation> {
  SavedPlacesController get _places =>
      widget.places ?? SavedPlacesController();

  @override
  Widget build(BuildContext context) {
    final shortcuts = _places.shortcuts();
    final homeSubtitle = _shortcutSubtitle(
      shortcuts,
      'home',
      fallback: 'Not saved yet',
    );
    final workSubtitle = _shortcutSubtitle(
      shortcuts,
      'office',
      fallback: 'Not saved yet',
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              50.height,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      height: ResSize.h * 26,
                      width: ResSize.w * 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.black,
                      ),
                      child: Icon(Icons.close, color: AppColor.white, size: 19),
                    ),
                  ),
                ],
              ),
              22.height,
              Container(
                padding: EdgeInsets.symmetric(vertical: ResSize.h * 8),
                decoration: BoxDecoration(
                  color: const Color(0xffF3F6FB),
                  border: Border.all(color: AppColor.border, width: 0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Stack(
                  children: [
                    customTextfield(
                      borderColor: Colors.transparent,
                      borderWidth: 0,
                      borderRadius: 0,
                      contentHorizPadding: 10,
                      hint: 'Pickup location',
                      contentVertPadding: 0,
                      fontSize: 16,
                      textColor: AppColor.black,
                      fillColor: Colors.transparent,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            // Did nothing at all. This screen returns a chosen
                            // place by popping it, the way the Home and Work
                            // shortcuts below already do.
                            onPressed: () =>
                                Navigator.maybePop(context, 'Current location'),
                            child: SizedBox(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Image.asset(
                                    AppAssets.gps,
                                    height: ResSize.h * 18,
                                    color: AppColor.black,
                                  ),
                                  4.width,
                                  TextWidget(
                                    text: 'CURRENT',
                                    fontSize: 8,
                                    fontWeight: fwBold,
                                    color: AppColor.black,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              2.height,
              Row(
                children: [
                  Expanded(
                    child: _buildSavedPlace(
                      icon: AppAssets.home,
                      title: 'Home',
                      subtitle: homeSubtitle,
                      isLeftRounded: true,
                      onTap: () => _onShortcutTap(subtitle: homeSubtitle),
                    ),
                  ),
                  2.width,
                  Expanded(
                    child: _buildSavedPlace(
                      icon: AppAssets.office,
                      title: 'Work',
                      subtitle: workSubtitle,
                      onTap: () => _onShortcutTap(subtitle: workSubtitle),
                    ),
                  ),
                  2.width,
                  InkWell(
                    // Was dead while the Home and Work chips beside it worked.
                    onTap: () => _onShortcutTap(subtitle: 'Not saved yet'),
                    child: _buildFavorite(),
                  ),
                ],
              ),
              10.height,
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResSize.w * 10,
                  vertical: ResSize.h * 14,
                ),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColor.liteBlue,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: 'Your last trip',
                      color: AppColor.black,
                      fontSize: 16,
                      fontWeight: fwSemiBold,
                    ),
                    10.height,
                    _buildEmptyState(
                      icon: Icons.history_rounded,
                      title: 'No recent trips yet',
                      subtitle:
                          'Completed trips will appear here when real ride history is available.',
                    ),
                  ],
                ),
              ),
              24.height,
              TextWidget(
                text: 'Search results',
                color: AppColor.black,
                fontSize: 16,
                fontWeight: fwSemiBold,
              ),
              10.height,
              _buildEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No search results',
                subtitle:
                    'Place search isn’t connected in this build yet.',
                backgroundColor: const Color(0xffF5F4F1),
              ),
              20.height,
            ],
          ),
        ),
      ),
    );
  }

  void _onShortcutTap({required String subtitle}) {
    final saved = subtitle.trim().isNotEmpty && subtitle != 'Not saved yet';
    if (saved) {
      Navigator.maybePop(context, subtitle);
      return;
    }
    Navigator.push(context, RightToLeftTransition(const AddPlace()));
  }

  double _chipHeight() {
    final scaled = ResSize.h * 57;
    return scaled < 56 ? 56 : scaled;
  }

  Widget _buildSavedPlace({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLeftRounded = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLeftRounded
            ? const BorderRadius.only(bottomLeft: Radius.circular(10))
            : BorderRadius.zero,
        child: Container(
          constraints: BoxConstraints(minHeight: _chipHeight()),
          decoration: BoxDecoration(
            borderRadius: isLeftRounded
                ? const BorderRadius.only(bottomLeft: Radius.circular(10))
                : null,
            color: AppColor.liteBlue,
            border: Border.all(color: AppColor.border, width: 0.5),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: ResSize.w * 10),
            child: Row(
              children: [
                Image.asset(icon, height: ResSize.h * 20),
                10.width,
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: title,
                        fontSize: 12,
                        fontWeight: fwSemiBold,
                        color: const Color(0xff5E5E5E),
                      ),
                      2.height,
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: fwNormal,
                          color: const Color(0xff5E5E5E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavorite() {
    return Container(
      constraints: BoxConstraints(minHeight: _chipHeight()),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(10)),
        color: AppColor.liteBlue,
        border: Border.all(color: AppColor.border, width: 0.5),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: ResSize.w * 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppAssets.star, height: ResSize.h * 18),
            4.height,
            TextWidget(
              text: 'Favorite',
              fontSize: 12,
              fontWeight: fwSemiBold,
              color: const Color(0xff5E5E5E),
            ),
          ],
        ),
      ),
    );
  }

  String _shortcutSubtitle(
    List<PlaceShortcut> shortcuts,
    String kind, {
    required String fallback,
  }) {
    for (final shortcut in shortcuts) {
      if (shortcut.kind == kind) {
        final subtitle = shortcut.subtitle.trim();
        if (subtitle.isNotEmpty) return subtitle;
      }
    }
    return fallback;
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    IconData icon = Icons.info_outline_rounded,
    Color? backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResSize.w * 10,
        vertical: ResSize.h * 12,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColor.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: ResSize.h * 18, color: AppColor.subtitle),
          8.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: title,
                  color: AppColor.black,
                  fontSize: 12,
                  fontWeight: fwSemiBold,
                ),
                2.height,
                TextWidget(
                  text: subtitle,
                  color: const Color(0xff5E5E5E),
                  fontSize: 10,
                  fontWeight: fwNormal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
