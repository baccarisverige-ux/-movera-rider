import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/constants/appassets.dart';
import 'package:movera_rider/constants/appcolors.dart';
import 'package:movera_rider/constants/appfontweight.dart';
import 'package:movera_rider/models/home_more_ways.dart';
import 'package:movera_rider/widgets/custom_text_widget.dart';
import 'package:movera_rider/widgets/responsive_size.dart';
import 'package:movera_rider/widgets/sizedbox_extention.dart';

// ignore: must_be_immutable
class PassengerHomeMoreWays extends StatelessWidget {
  PassengerHomeMoreWays({super.key});
  List<HomeMoreWaysModel> ways = [
    HomeMoreWaysModel(
      image: AppAssets.choosecomfort,
      title: "Choose Comfort",
      subTitle: "Lorem ipsum dolor sit amet consectetur.",
    ),
    HomeMoreWaysModel(
      image: AppAssets.rideWithConfidence,
      title: "Ride with confidence",
      subTitle: "Lorem ipsum dolor sit amet consectetur.",
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: "More way to use Driver",
          fontSize: ResSize.setSp(18),
          fontWeight: fwSemiBold,
          color: AppColor.primary,
        ),
        8.height,
        SizedBox(
          height: ResSize.h * 190,
          child: ListView.builder(
            itemCount: ways.length,
            shrinkWrap: true,
            physics: BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : ResSize.h * 16),
                child: SizedBox(
                  width: ResSize.w * 290,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          width: ResSize.w * 290,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: AssetImage(ways[index].image),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      12.height,
                      TextWidget(
                        text: ways[index].title,
                        fontSize: ResSize.setSp(18),
                        color: AppColor.title,
                        fontWeight: fwSemiBold,
                      ),
                      2.height,
                      Text(
                        ways[index].subTitle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.poppins(
                          fontSize: ResSize.setSp(14),
                          color: AppColor.subtitle,
                          fontWeight: fwNormal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
