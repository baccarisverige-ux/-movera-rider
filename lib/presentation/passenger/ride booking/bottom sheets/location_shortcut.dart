// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/constants/appassets.dart';
import 'package:movera_rider/constants/appcolors.dart';
import 'package:movera_rider/constants/appfontweight.dart';
import 'package:movera_rider/models/image_title.dart';
import 'package:movera_rider/widgets/custom_btn.dart';
import 'package:movera_rider/widgets/custom_text_widget.dart';
import 'package:movera_rider/widgets/responsive_size.dart';
import 'package:movera_rider/widgets/sizedbox_extention.dart';
import 'package:dotted_line/dotted_line.dart';

class BookRideLocationShortcuts extends StatefulWidget {
  final VoidCallback onNext;
  const BookRideLocationShortcuts({super.key, required this.onNext});

  @override
  State<BookRideLocationShortcuts> createState() =>
      _BookRideLocationShortcutsState();
}

class _BookRideLocationShortcutsState extends State<BookRideLocationShortcuts> {
  List<ImageTitleModel> quickAccess = [
    ImageTitleModel(image: AppAssets.home, title: "Home"),
    ImageTitleModel(image: AppAssets.work, title: "Work"),
    ImageTitleModel(image: AppAssets.recent, title: "Recent"),
    ImageTitleModel(image: AppAssets.saved, title: "Save"),
  ];
  int selectedShortCut = 0;
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
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: widget.onNext,
                child: Container(
                  height: ResSize.h * 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColor.border, width: 1),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: ResSize.w * 12),
                    child: Row(
                      children: [
                        Image.asset(
                          AppAssets.search,
                          height: ResSize.h * 24,
                          color: AppColor.hintText,
                        ),
                        10.width,
                        TextWidget(
                          text: "Where are you going?",
                          color: AppColor.hintText,
                          fontSize: ResSize.setSp(16),
                          fontWeight: fwMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              12.height,
              SizedBox(
                height: ResSize.h * 40,
                child: ListView.builder(
                  itemCount: quickAccess.length,
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: BouncingScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 0 : ResSize.w * 6,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                selectedShortCut = index;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResSize.w * 8,
                                vertical: ResSize.h * 9,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: selectedShortCut == index
                                    ? AppColor.primary
                                    : Color(0xffF6F6F6),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    quickAccess[index].image,
                                    height: ResSize.h * 20,
                                    color: selectedShortCut == index
                                        ? AppColor.secondary
                                        : AppColor.subtitle,
                                  ),
                                  8.width,
                                  TextWidget(
                                    text: quickAccess[index].title,
                                    color: selectedShortCut == index
                                        ? AppColor.secondary
                                        : AppColor.subtitle,
                                    fontSize: 14,
                                    fontWeight: fwMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              12.height,
              TextWidget(
                text: "Home Location",
                color: AppColor.primary,
                fontSize: 18,
                fontWeight: fwSemiBold,
              ),
              12.height,
              Row(
                children: [
                  SizedBox(
                    height: ResSize.h * 95,
                    child: Column(
                      children: [
                        Container(
                          height: ResSize.h * 34,
                          width: ResSize.w * 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xffF6F6F6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset(
                              AppAssets.pickup,
                              color: AppColor.subtitle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: DottedLine(
                            dashLength: 3,
                            dashGapLength: 3,
                            lineThickness: 1.4,
                            dashRadius: 0,
                            dashColor: AppColor.subtitle,
                            direction: Axis.vertical,
                          ),
                        ),
                        Container(
                          height: ResSize.h * 34,
                          width: ResSize.w * 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xffF6F6F6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset(
                              AppAssets.home,
                              color: AppColor.subtitle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  8.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          "1901 Thornridge Cir. Shiloh, Hawaii 81063",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: fwNormal,
                            color: AppColor.subtitle,
                          ),
                        ),
                        40.height,
                        Text(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          "1901 Thornridge Cir. Shiloh, Hawaii 81063",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: fwNormal,
                            color: AppColor.subtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              16.height,
              CustomButton(
                centerContent: "Find Ride",
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
