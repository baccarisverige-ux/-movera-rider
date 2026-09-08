// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/rider/my%20rides/components/appbar.dart';
import 'package:movera/presentation/rider/my%20rides/components/confirmed.dart';
import 'package:movera/presentation/rider/my%20rides/components/requests.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';
import 'package:animated_segmented_tab_control/animated_segmented_tab_control.dart';

class MyRidesScreen extends StatelessWidget {
  const MyRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ResSize.h * 60),
        child: ScheduleRideAppBar(),
      ),
      body: SizedBox(
        child: Column(
          children: [
            Container(height: ResSize.h * 6, color: Color(0xffFAFAFA)),
            15.height,
            Expanded(
              child: DefaultTabController(
                length: 2,
                initialIndex: 0,

                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenHorizPadding,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Color(0xffF6F6F6),
                        ),
                        child: SegmentedTabControl(
                          tabTextColor: AppColor.subtitle,
                          // Customization of widget
                          selectedTabTextColor: AppColor.title,
                          indicatorPadding: const EdgeInsets.all(0),
                          indicatorDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: AppColor.white,
                          ),
                          height: ResSize.h * 36,
                          barDecoration: BoxDecoration(
                            color: Colors.transparent,
                          ),
                          textStyle: GoogleFonts.poppins(
                            fontSize: ResSize.setSp(14),
                            fontWeight: fwMedium,
                          ),
                          selectedTextStyle: GoogleFonts.poppins(
                            fontSize: ResSize.setSp(14),
                            fontWeight: fwMedium,
                          ),
                          // Options for selection
                          // All specified values will override the [SegmentedTabControl] setting
                          tabs: [
                            SegmentTab(
                              label: 'Requests',

                              // For example, this overrides [indicatorColor] from [SegmentedTabControl]
                            ),
                            SegmentTab(label: 'Confirmed'),
                          ],
                        ),
                      ),
                    ),
                    20.height,

                    // Sample pages
                    Expanded(
                      child: TabBarView(
                        clipBehavior: Clip.none,
                        physics: const BouncingScrollPhysics(),
                        children: [RequestsRide(), ConfirmedsRide()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
