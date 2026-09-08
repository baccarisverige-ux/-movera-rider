import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/rider/choose%20route/components/appbar.dart';
import 'package:movera_rider/features/rider/choose%20route/set%20on%20map/set_on_map.dart';
import 'package:movera_rider/features/rider/saved%20places/saved_places.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/custom_textfield.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class ChooseRoute extends StatefulWidget {
  const ChooseRoute({super.key});

  @override
  State<ChooseRoute> createState() => _ChooseRouteState();
}

class _ChooseRouteState extends State<ChooseRoute> {
  // Track extra textfields
  List<int> extraFields = [];

  void _addField() {
    if (extraFields.length < 5) {
      setState(() {
        extraFields.add(DateTime.now().millisecondsSinceEpoch); // unique id
      });
    }
  }

  void _removeField(int id) {
    setState(() {
      extraFields.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9F9),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ResSize.h * 70),
        child: ChooseRouteAppBar(
          onAddPressed: _addField, // ✅ add new textfield
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
            decoration: BoxDecoration(
              color: AppColor.white,
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: const Color(0xff7E7E7E).withOpacity(0.11),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                16.height,
                // 🔹 First row (Home, Office, Favorite)
                Row(
                  children: [
                    Expanded(
                      child: _buildSavedPlace(
                        icon: AppAssets.home,
                        title: "Home",
                        subtitle: "3.5km| Dubai hotel...",
                        isLeftRounded: true,
                      ),
                    ),
                    2.width,
                    Expanded(
                      child: _buildSavedPlace(
                        icon: AppAssets.office,
                        title: "Office",
                        subtitle: "5.1km| Sharjah mall...",
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          BottomToTopTransition(SavedPlaces()),
                        );
                      },
                      child: _buildFavorite(),
                    ),
                  ],
                ),
                8.height,

                // 🔹 Pickup field
                customTextfield(
                  contentVertPadding: 16,
                  borderColor: Colors.transparent,
                  borderWidth: 0,
                  prefixWidget: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      AppAssets.gps,
                      height: ResSize.h * 25,
                      color: AppColor.title,
                    ),
                  ),
                  fillColor: AppColor.liteBlue,
                  hint: "Add pickup",
                ),
                8.height,
                Column(
                  children: extraFields.map((id) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: customTextfield(
                              contentVertPadding: 16,
                              borderColor: Colors.transparent,
                              borderWidth: 0,
                              prefixWidget: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Transform.scale(
                                  scale: 0.8,
                                  child: Image.asset(
                                    AppAssets.stop,
                                    height: ResSize.h * 25,
                                    color: AppColor.title,
                                  ),
                                ),
                              ),
                              fillColor: AppColor.liteBlue,
                              hint: "Add a stop",
                            ),
                          ),
                          10.width,
                          InkWell(
                            onTap: () => _removeField(id),
                            child: Image.asset(
                              AppAssets.removeStop,
                              height: ResSize.h * 22,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                // 🔹 Destination field
                customTextfield(
                  contentVertPadding: 16,
                  borderColor: Colors.transparent,
                  borderWidth: 0,
                  prefixWidget: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      AppAssets.location,
                      height: ResSize.h * 23,
                      color: AppColor.title,
                    ),
                  ),
                  fillColor: AppColor.liteBlue,
                  hint: "Add a destination",
                ),

                // 🔹 Dynamically added fields
                16.height,
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: InkWell(
        onTap: () {
          Navigator.push(
            context,
            TopToBottomTransition(const ChooseRouteOnMap()),
          );
        },
        child: Container(
          height: ResSize.h * 66,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColor.white,
            boxShadow: [
              BoxShadow(
                color: AppColor.black.withOpacity(0.25),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(AppAssets.gps, height: ResSize.h * 24),
              10.width,
              TextWidget(
                text: "Set on map",
                color: AppColor.title,
                fontSize: 16,
                fontWeight: fwMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Helper widget for saved places
  Widget _buildSavedPlace({
    required String icon,
    required String title,
    required String subtitle,
    bool isLeftRounded = false,
  }) {
    return Container(
      height: ResSize.h * 57,
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
    );
  }

  // 🔹 Favorite Box
  Widget _buildFavorite() {
    return Container(
      height: ResSize.h * 57,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(10)),
        color: AppColor.liteBlue,
        border: Border.all(color: AppColor.border, width: 0.5),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: ResSize.w * 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppAssets.star, height: ResSize.h * 18),
            4.height,
            TextWidget(
              text: "Favorite",
              fontSize: 12,
              fontWeight: fwSemiBold,
              color: const Color(0xff5E5E5E),
            ),
          ],
        ),
      ),
    );
  }
}
