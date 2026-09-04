import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/models/home_more_ways.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

// ignore: must_be_immutable
class PassengerServicesScreen extends StatelessWidget {
  PassengerServicesScreen({super.key});
  List<HomeMoreWaysModel> services = [
    HomeMoreWaysModel(
      image: AppAssets.rides,
      title: "Rides",
      subTitle: "Comfortable, reliable rides for your everyday tra...",
    ),
    HomeMoreWaysModel(
      image: AppAssets.airportRides,
      title: "Airport Rides",
      subTitle: "On-time airport pickups and drop-offs with stress...",
    ),
    HomeMoreWaysModel(
      image: AppAssets.cityTour,
      title: "City Tour",
      subTitle: "Explore the city’s top attractions with flexibl....",
    ),
    HomeMoreWaysModel(
      image: AppAssets.rideBusiness,
      title: "Rides for Business",
      subTitle: "Professional executive rides designed for meeti....",
    ),
    HomeMoreWaysModel(
      image: AppAssets.luxury,
      title: "Luxury Car Rentals",
      subTitle: "Premium vehicles for stylish and comfortable....",
    ),
    HomeMoreWaysModel(
      image: AppAssets.fullDay,
      title: "Full Day Chauffeur",
      subTitle: "Dedicated driver service for your entire day, on yo...",
    ),
    HomeMoreWaysModel(
      image: AppAssets.courier,
      title: "Courier Service",
      subTitle: "Fast and secure delivery with real-time tracki....",
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
        child: Column(
          children: [
            50.height,
            TextWidget(
              text: "Services",
              fontSize: ResSize.setSp(18),
              fontWeight: fwBold,
              color: AppColor.primary,
            ),
            32.height,
            GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: ResSize.w * 16,
                mainAxisSpacing: ResSize.h * 16,
                mainAxisExtent: ResSize.h * 148,
              ),
              itemCount: services.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              clipBehavior: Clip.none,
              padding: EdgeInsets.zero,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColor.secondary,
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Color(0xff000000).withOpacity(0.08),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: ResSize.h * 8),
                    child: Column(
                      children: [
                        Expanded(child: Image.asset(services[index].image)),
                        6.height,
                        TextWidget(
                          text: services[index].title,
                          fontSize: ResSize.setSp(13.5),
                          color: AppColor.title,
                          fontWeight: fwSemiBold,
                          textAlign: TextAlign.center,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResSize.w * 8,
                          ),
                          child: Text(
                            services[index].subTitle,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: ResSize.setSp(12),
                              color: AppColor.subtitle,
                              fontWeight: fwNormal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            50.height,
          ],
        ),
      ),
    );
  }
}
