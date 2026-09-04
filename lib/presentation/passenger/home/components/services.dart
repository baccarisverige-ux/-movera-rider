import 'package:flutter/material.dart';
import 'package:movera_rider/constants/appassets.dart';
import 'package:movera_rider/constants/appcolors.dart';
import 'package:movera_rider/constants/appfontweight.dart';
import 'package:movera_rider/models/image_title.dart';
import 'package:movera_rider/widgets/custom_text_widget.dart';
import 'package:movera_rider/widgets/responsive_size.dart';
import 'package:movera_rider/widgets/sizedbox_extention.dart';

// ignore: must_be_immutable
class PassengerHomeServices extends StatelessWidget {
  PassengerHomeServices({super.key});
  List<ImageTitleModel> services = [
    ImageTitleModel(image: AppAssets.rides, title: "Rides"),
    ImageTitleModel(image: AppAssets.cityTour, title: "City Tour"),
    ImageTitleModel(image: AppAssets.airportRides, title: "Airport Rides"),
    ImageTitleModel(image: AppAssets.rides, title: "Rides"),
  ];
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: "Services",
          fontSize: ResSize.setSp(18),
          color: AppColor.primary,
          fontWeight: fwSemiBold,
        ),
        10.height,
        SizedBox(
          height: ResSize.h * 100,
          child: ListView.builder(
            itemCount: services.length,
            shrinkWrap: true,
            physics: BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : ResSize.h * 16),
                child: Container(
                  height: ResSize.h * 100,
                  width: ResSize.w * 120,
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
                    padding: EdgeInsets.symmetric(vertical: ResSize.h * 10),
                    child: Column(
                      children: [
                        Expanded(child: Image.asset(services[index].image)),
                        6.height,
                        TextWidget(
                          text: services[index].title,
                          fontSize: ResSize.setSp(13),
                          color: AppColor.title,
                          fontWeight: fwMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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
