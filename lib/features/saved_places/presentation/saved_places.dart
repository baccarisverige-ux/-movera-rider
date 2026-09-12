import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/saved_places/application/saved_places_controller.dart';
import 'package:movera_rider/shared/models/saved_places.dart';
import 'package:movera_rider/features/saved_places/presentation/add_place.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class SavedPlaces extends StatelessWidget {
  SavedPlaces({super.key});
  List<SavedPlacesModel> savedPlaces = SavedPlacesController().options();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              55.height,
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  height: ResSize.h * 30,
                  width: ResSize.w * 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColor.white,
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Color(0xff999999).withOpacity(0.4),
                        blurRadius: 40,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: AppColor.title,
                      size: ResSize.h * 16,
                    ),
                  ),
                ),
              ),
              16.height,
              TextWidget(
                text: "Saved Places",
                color: AppColor.title,
                fontSize: 20,
                fontWeight: fwMedium,
              ),
              TextWidget(
                text: "The driver will take you where you’re going",
                color: AppColor.subtitle,
                fontSize: 14,
                fontWeight: fwMedium,
              ),
              24.height,
              ...List.generate(savedPlaces.length, (index) {
                return InkWell(
                  onTap: () {
                    Navigator.push(context, RightToLeftTransition(AddPlace()));
                  },
                  child: Column(
                    children: [
                      12.height,
                      Row(
                        children: [
                          Row(
                            children: [
                              Icon(
                                savedPlaces[index].icon,
                                color: AppColor.subtitle,
                                size: ResSize.h * 24,
                              ),
                            ],
                          ),
                          10.width,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextWidget(
                                  text: savedPlaces[index].title,
                                  color: AppColor.subtitle,
                                  fontSize: 14,
                                  fontWeight: fwMedium,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColor.subtitle,
                            size: ResSize.h * 18,
                          ),
                        ],
                      ),
                      12.height,
                      Padding(
                        padding: EdgeInsets.only(left: ResSize.w * 36),
                        child: Divider(color: AppColor.border, thickness: 0.5),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
