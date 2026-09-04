// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/models/home_more_ways.dart';
import 'package:riding_app/widgets/custom_btn.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/custom_textfield.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class BookRideLocationSelection extends StatefulWidget {
  final VoidCallback onNext;
  const BookRideLocationSelection({super.key, required this.onNext});

  @override
  State<BookRideLocationSelection> createState() =>
      _BookRideLocationSelectionState();
}

class _BookRideLocationSelectionState extends State<BookRideLocationSelection> {
  List<HomeMoreWaysModel> suggestionList = [
    HomeMoreWaysModel(
      image: AppAssets.location,
      title: "Home Location",
      subTitle: "1901 Thornridge Cir. Shiloh, Hawaii 81063",
    ),
    HomeMoreWaysModel(
      image: AppAssets.location,
      title: "Work",
      subTitle: "1901 Thornridge Cir. Shiloh, Hawaii 81063",
    ),
  ];
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
                text: "Pickup",
                color: AppColor.primary,
                fontSize: 16,
                fontWeight: fwMedium,
              ),
              6.height,
              customTextfield(hint: "1901 Thornridge Cir. Shiloh,...."),
              12.height,
              TextWidget(
                text: "Destination",
                color: AppColor.primary,
                fontSize: 16,
                fontWeight: fwMedium,
              ),
              6.height,
              customTextfield(
                hint: "Search Location",
                prefixWidget: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Image.asset(
                    AppAssets.search,
                    height: ResSize.h * 24,
                    width: ResSize.w * 24,
                    color: AppColor.hintText,
                  ),
                ),
              ),

              12.height,
              TextWidget(
                text: "Suggestions List",
                color: AppColor.primary,
                fontSize: 18,
                fontWeight: fwSemiBold,
              ),
              12.height,
              ListView.builder(
                itemCount: suggestionList.length,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 ? 0 : ResSize.h * 12,
                    ),
                    child: InkWell(
                      onTap: () {},
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
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
                            horizontal: ResSize.w * 8,
                            vertical: ResSize.h * 8,
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: ResSize.h * 45,
                                width: ResSize.w * 45,
                                decoration: BoxDecoration(
                                  color: Color(0xffF6F6F6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Image.asset(
                                    AppAssets.location,
                                    height: ResSize.h * 20,
                                    color: AppColor.subtitle,
                                  ),
                                ),
                              ),
                              8.width,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextWidget(
                                      text: suggestionList[index].title,
                                      color: AppColor.primary,
                                      fontSize: 16,
                                      fontWeight: fwMedium,
                                    ),
                                    2.height,
                                    Text(
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      suggestionList[index].subTitle,
                                      style: GoogleFonts.poppins(
                                        color: AppColor.subtitle,
                                        fontSize: 14,
                                        fontWeight: fwNormal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: ResSize.h * 18,
                                color: AppColor.subtitle,
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
