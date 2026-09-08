import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/rider/saved%20places/add%20place/components/confirm_location.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/custom_textfield.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class RiderSearchPickupLocation extends StatefulWidget {
  const RiderSearchPickupLocation({super.key});

  @override
  State<RiderSearchPickupLocation> createState() =>
      _RiderSearchPickupLocationState();
}

class _RiderSearchPickupLocationState extends State<RiderSearchPickupLocation> {
  List<bool> trips = List.generate(3, (index) {
    return false;
  });

  @override
  Widget build(BuildContext context) {
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
                      Navigator.of(context).pop(); // Closes the dialog
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
                  color: Color(0xffF3F6FB),
                  border: Border.all(color: AppColor.border, width: 0.5),
                  borderRadius: BorderRadius.only(
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
                      hint: "Pick-Up Location",
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
                            onPressed: () {},
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
                                    text: "CURRENT",
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
                  2.width,
                  InkWell(
                    onTap: () {
                      // Navigator.push(
                      //   context,
                      //   BottomToTopTransition(SavedPlaces()),
                      // );
                    },
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
                      text: "Your Last Trip",
                      color: AppColor.black,
                      fontSize: 16,
                      fontWeight: fwSemiBold,
                    ),
                    10.height,
                    ...List.generate(trips.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 0 : ResSize.h * 5,
                        ),
                        child: InkWell(
                          onTap: () {
                            showPickupLocationBottomSheet(context);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResSize.w * 10,
                              vertical: ResSize.h * 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColor.border,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  AppAssets.location,
                                  height: ResSize.h * 24,
                                ),
                                12.width,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextWidget(
                                        text: "30 Main Street",
                                        color: AppColor.black,
                                        fontSize: 12,
                                        fontWeight: fwSemiBold,
                                      ),
                                      2.height,
                                      TextWidget(
                                        text: "5.9km|30 Main Street, London",
                                        color: Color(0xff5E5E5E),
                                        fontSize: 10,
                                        fontWeight: fwNormal,
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      trips[index] = !trips[index];
                                    });
                                  },
                                  child: Container(
                                    child: trips[index]
                                        ? Image.asset(
                                            AppAssets.starFill,
                                            height: ResSize.h * 22,
                                          )
                                        : Image.asset(
                                            AppAssets.star,
                                            color: Color(0xff083321),
                                            height: ResSize.h * 22,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              24.height,
              TextWidget(
                text: "Search Result",
                color: AppColor.black,
                fontSize: 16,
                fontWeight: fwSemiBold,
              ),
              10.height,
              ...List.generate(8, (index) {
                return Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : ResSize.h * 5),
                  child: InkWell(
                    onTap: () {
                      showPickupLocationBottomSheet(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResSize.w * 10,
                        vertical: ResSize.h * 8,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xffF5F4F1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColor.border, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            AppAssets.location,
                            height: ResSize.h * 24,
                          ),
                          12.width,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextWidget(
                                  text: "30 Main Street",
                                  color: AppColor.black,
                                  fontSize: 12,
                                  fontWeight: fwSemiBold,
                                ),
                                2.height,
                                TextWidget(
                                  text: "5.9km|30 Main Street, London",
                                  color: Color(0xff5E5E5E),
                                  fontSize: 10,
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
              }),
              20.height,
            ],
          ),
        ),
      ),
    );
  }

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
