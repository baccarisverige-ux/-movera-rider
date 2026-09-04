// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/constants/appassets.dart';
import 'package:movera_rider/constants/appcolors.dart';
import 'package:movera_rider/constants/appfontweight.dart';
import 'package:movera_rider/models/home_more_ways.dart';
import 'package:movera_rider/widgets/custom_btn.dart';
import 'package:movera_rider/widgets/custom_text_widget.dart';
import 'package:movera_rider/widgets/responsive_size.dart';
import 'package:movera_rider/widgets/sizedbox_extention.dart';

class BookRideRideOptions extends StatefulWidget {
  final VoidCallback onNext;
  const BookRideRideOptions({super.key, required this.onNext});

  @override
  State<BookRideRideOptions> createState() => _BookRideRideOptionsState();
}

class _BookRideRideOptionsState extends State<BookRideRideOptions> {
  List<HomeMoreWaysModel> rideOptions = [
    HomeMoreWaysModel(
      image: AppAssets.standard,
      title: "Standard",
      subTitle: "up to 4 seats",
    ),
    HomeMoreWaysModel(
      image: AppAssets.xl,
      title: "XL",
      subTitle: "up to 7 seats",
    ),
    HomeMoreWaysModel(
      image: AppAssets.future,
      title: "Future",
      subTitle: "Executive",
    ),
  ];
  int selectedOption = 0;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.secondary,
          boxShadow: [
            BoxShadow(
              color: Color(0xff000000).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResSize.w * 12,
            vertical: ResSize.h * 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text: "Trip Summary",
                color: AppColor.primary,
                fontSize: 18,
                fontWeight: fwSemiBold,
              ),
              6.height,
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: "From",
                          color: AppColor.subtitle,
                          fontSize: 14,
                          fontWeight: fwNormal,
                        ),
                        2.height,
                        Text(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          "1901 Thornridge Cir. Shiloh....",
                          style: GoogleFonts.poppins(
                            color: AppColor.primary,
                            fontSize: 16,
                            fontWeight: fwMedium,
                          ),
                        ),
                        8.height,
                        TextWidget(
                          text: "To",
                          color: AppColor.subtitle,
                          fontSize: 14,
                          fontWeight: fwNormal,
                        ),
                        2.height,
                        Text(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          "1901 Thornridge Cir. Shiloh....",
                          style: GoogleFonts.poppins(
                            color: AppColor.primary,
                            fontSize: 16,
                            fontWeight: fwMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  20.width,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: ResSize.h * 30,
                            width: ResSize.w * 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xffF8F8F8),
                            ),
                            child: Center(
                              child: Image.asset(
                                AppAssets.time,
                                height: ResSize.h * 18,
                                color: AppColor.subtitle,
                              ),
                            ),
                          ),
                          4.width,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWidget(
                                text: "Time",
                                color: AppColor.subtitle,
                                fontSize: 12,
                                fontWeight: fwNormal,
                              ),
                              TextWidget(
                                text: "EST:12mins",
                                color: AppColor.primary,
                                fontSize: 14,
                                fontWeight: fwNormal,
                              ),
                            ],
                          ),
                        ],
                      ),
                      20.height,
                      Row(
                        children: [
                          Container(
                            height: ResSize.h * 30,
                            width: ResSize.w * 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xffF8F8F8),
                            ),
                            child: Center(
                              child: Image.asset(
                                AppAssets.distance,
                                height: ResSize.h * 18,
                                color: AppColor.subtitle,
                              ),
                            ),
                          ),
                          4.width,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWidget(
                                text: "Distance",
                                color: AppColor.subtitle,
                                fontSize: 12,
                                fontWeight: fwNormal,
                              ),
                              TextWidget(
                                text: "14 Km",
                                color: AppColor.primary,
                                fontSize: 14,
                                fontWeight: fwNormal,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              8.height,
              Divider(color: AppColor.border, thickness: 0.4),

              8.height,
              TextWidget(
                text: "Ride Option",
                color: AppColor.primary,
                fontSize: 18,
                fontWeight: fwSemiBold,
              ),
              12.height,
              ListView.builder(
                itemCount: rideOptions.length,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 ? 0 : ResSize.h * 6,
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedOption = index;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: selectedOption == index
                                ? AppColor.primary
                                : Colors.transparent,
                            width: selectedOption == index ? 1.4 : 0,
                          ),
                          color: selectedOption == index
                              ? Color(0xff141414).withOpacity(0.05)
                              : Colors.transparent,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResSize.w * 6,
                            vertical: ResSize.h * 6,
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: ResSize.h * 45,
                                width: ResSize.w * 45,
                                decoration: BoxDecoration(
                                  color: selectedOption == index
                                      ? AppColor.secondary
                                      : Color(0xffF6F6F6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Image.asset(
                                    rideOptions[index].image,
                                    height: ResSize.h * 20,
                                    color: selectedOption == index
                                        ? AppColor.primary
                                        : AppColor.subtitle,
                                  ),
                                ),
                              ),
                              8.width,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextWidget(
                                      text: rideOptions[index].title,
                                      color: AppColor.primary,
                                      fontSize: 16,
                                      fontWeight: fwMedium,
                                    ),
                                    2.height,
                                    TextWidget(
                                      text: rideOptions[index].subTitle,
                                      color: AppColor.subtitle,
                                      fontSize: 14,
                                      fontWeight: fwNormal,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  TextWidget(
                                    text: "\$5 - \$10",
                                    color: AppColor.primary,
                                    fontSize: 16,
                                    fontWeight: fwMedium,
                                  ),
                                  2.height,
                                  TextWidget(
                                    text: "Arrive in 4min",
                                    color: AppColor.subtitle,
                                    fontSize: 14,
                                    fontWeight: fwNormal,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              16.height,
              CustomButton(
                centerContent: "Next",
                onPressed: widget.onNext,
                fontSize: 16,
                height: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
