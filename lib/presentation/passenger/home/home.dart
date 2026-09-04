import 'package:flutter/material.dart';
import 'package:movera_rider/constants/appassets.dart';
import 'package:movera_rider/constants/appfontweight.dart';
import 'package:movera_rider/presentation/passenger/home/components/banner.dart';
import 'package:movera_rider/presentation/passenger/home/components/more_ways.dart';
import 'package:movera_rider/presentation/passenger/home/components/saved_places.dart';
import 'package:movera_rider/presentation/passenger/home/components/services.dart';
import 'package:movera_rider/presentation/passenger/ride%20booking/ride_booking.dart';
import 'package:movera_rider/widgets/custom_text_widget.dart';
import 'package:movera_rider/widgets/navigation_transition.dart';
import 'package:movera_rider/widgets/responsive_size.dart';
import 'package:movera_rider/widgets/sizedbox_extention.dart';

class PassengerHomeScreen extends StatelessWidget {
  const PassengerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
        child: Column(
          children: [
            50.height,
            InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () {
                Navigator.push(
                  context,
                  TopToBottomTransition(RideBookingScreen()),
                );
              },
              child: Container(
                height: ResSize.h * 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xff3F3F3F), width: 1),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: ResSize.w * 12),
                  child: Row(
                    children: [
                      Image.asset(AppAssets.search, height: ResSize.h * 24),
                      10.width,
                      TextWidget(
                        text: "Where are you going?",
                        color: Color(0xff3F3F3F),
                        fontSize: ResSize.setSp(16),
                        fontWeight: fwMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            19.height,
            PassengerHomeSavedPlaces(),
            16.height,
            PassengerHomeServices(),
            24.height,
            PassengerHomeMoreWays(),
            24.height,
            PassengerHomeBanner(),
            44.height,
          ],
        ),
      ),
    );
  }
}
