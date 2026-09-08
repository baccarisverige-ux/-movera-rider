import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/shared/models/onboarding.dart';
import 'package:movera_rider/shared/widgets/custom_btn.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';
import 'package:readmore/readmore.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class ScheduleSelectRide extends StatefulWidget {
  final VoidCallback onConfirm;
  final Widget body;
  const ScheduleSelectRide({
    super.key,
    required this.body,
    required this.onConfirm,
  });

  @override
  State<ScheduleSelectRide> createState() => _ScheduleSelectRideState();
}

class _ScheduleSelectRideState extends State<ScheduleSelectRide> {
  List<OnBoardingModel> ridesList = [
    OnBoardingModel(
      image: AppAssets.mini,
      title: "Mini Ride",
      subTitle: "\$5.00",
    ),
    OnBoardingModel(
      image: AppAssets.ecoFriendly,
      title: "Eco-Friendy",
      subTitle: "\$7.50",
    ),
    OnBoardingModel(image: AppAssets.xl, title: "XL", subTitle: "\$17.00"),
    OnBoardingModel(
      image: AppAssets.luxury,
      title: "Luxury",
      subTitle: "\$27.00",
    ),
  ];
  int selectedRide = 1;

  @override
  Widget build(BuildContext context) {
    return SlidingUpPanel(
      color: AppColor.white,
      backdropColor: Colors.transparent,
      margin: EdgeInsets.all(0),
      minHeight: ResSize.h * 370,
      padding: EdgeInsets.symmetric(
        horizontal: screenHorizPadding,
        vertical: ResSize.h * 16,
      ),
      boxShadow: [],
      isDraggable: true,
      defaultPanelState: PanelState.CLOSED,
      maxHeight: ResSize.h * 370,
      parallaxEnabled: false,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      panelBuilder: (ScrollController sc) => panelColumn(sc),
      // panelBuilder: (ScrollController sc) => panelColumn(sc, context),
      body: widget.body,
    );
  }

  Widget panelColumn(ScrollController sc) {
    return SingleChildScrollView(
      controller: sc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            fontSize: 14,
            fontWeight: fwMedium,
            text: "Available options",
            color: AppColor.title,
          ),
          8.height,
          SizedBox(
            height: ResSize.h * 75,
            child: ListView.builder(
              itemCount: ridesList.length,
              shrinkWrap: true,
              clipBehavior: Clip.none,
              padding: EdgeInsets.all(0),
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedRide = index;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: selectedRide == index
                          ? Color(
                              0xff215277,
                              // ignore: deprecated_member_use
                            ).withOpacity(0.10)
                          : Colors.transparent,
                    ),
                    height: ResSize.h * 75,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: ResSize.w * 13,
                        right: ResSize.w * 13,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Transform.scale(
                              scale:
                                  ridesList[index].image ==
                                      AppAssets.ecoFriendly
                                  ? 1.45
                                  : ridesList[index].image == AppAssets.xl
                                  ? 1
                                  : 1.2,
                              child: Transform.translate(
                                offset: ridesList[index].image == AppAssets.xl
                                    ? Offset(-5, 5)
                                    : ridesList[index].image ==
                                          AppAssets.ecoFriendly
                                    ? Offset(3, 0)
                                    : Offset(0, 0),
                                child: Image.asset(ridesList[index].image),
                              ),
                            ),
                          ),
                          TextWidget(
                            fontSize: 12,
                            fontWeight: fwSemiBold,
                            text: ridesList[index].title,
                            color: AppColor.black,
                          ),
                          TextWidget(
                            fontSize: 12,
                            fontWeight: fwNormal,
                            text: ridesList[index].subTitle,
                            color: AppColor.black,
                          ),
                          4.height,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          16.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextWidget(
                text: "Price per ride",
                color: AppColor.title,
                fontSize: 14,
                fontWeight: fwSemiBold,
              ),
              TextWidget(
                text: "\$57.00",
                color: AppColor.title,
                fontSize: 16,
                fontWeight: fwSemiBold,
              ),
            ],
          ),
          10.height,

          ReadMoreText(
            textAlign: TextAlign.start,
            '''
      • Includes 1 hour of complimentary wait time.
      • All-inclusive rates (including Meet & Greet).
      • Free cancellation up until 1 hour before pickup.
      • Professional drivers with luxury vehicles.
      • 24/7 customer support.
        ''',
            trimLines: 3, // number of lines to show before "Read more"
            colorClickableText: Color(0xff0D4A31),
            moreStyle: GoogleFonts.inter(
              fontSize: ResSize.setSp(12),
              fontWeight: fwBold,
            ),
            trimMode: TrimMode.Line,
            trimCollapsedText: '\nRead more',
            trimExpandedText: 'Read less',
            style: GoogleFonts.poppins(
              color: AppColor.title,
              fontSize: ResSize.setSp(14),
              fontWeight: fwNormal,
            ),
          ),

          19.height,
          CustomButton(
            centerContent: "Confirm",
            onPressed: () {
              widget.onConfirm();
            },
          ),
          40.height,
        ],
      ),
    );
  }
}
