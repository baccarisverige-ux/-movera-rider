import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/scheduled_rides/application/scheduled_rides_controller.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/custom_textfield.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class ScheduleAddNote extends StatefulWidget {
  final VoidCallback onConfirm;
  final Widget body;
  final ScheduledRideSession? session;
  const ScheduleAddNote({
    super.key,
    required this.body,
    required this.onConfirm,
    this.session,
  });

  @override
  State<ScheduleAddNote> createState() => _ScheduleAddNoteState();
}

class _ScheduleAddNoteState extends State<ScheduleAddNote> {
  bool showTextField = false; // ✅ to toggle edit mode
  String noteText = "You have not added any notes"; // ✅ default text
  final TextEditingController _noteController = TextEditingController();

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
        children: [
          Center(
            child: Transform.scale(
              scale: 1.3,
              child: Image.asset(
                AppAssets.scheduleRideCar,
                height: ResSize.h * 90,
              ),
            ),
          ),
          0.height,
          TextWidget(
            text: "Comfort SUV",
            fontSize: 20,
            fontWeight: fwBold,
            color: AppColor.darkTitle,
          ),
          4.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(AppAssets.profile_2user, height: ResSize.h * 14),
              4.width,
              TextWidget(
                text: "4 Passengers",
                fontSize: 12,
                fontWeight: fwMedium,
                color: AppColor.darkTitle,
              ),
              10.width,
              Image.asset(AppAssets.suitcases, height: ResSize.h * 14),
              4.width,
              TextWidget(
                text: "3 Suitcases",
                fontSize: 12,
                fontWeight: fwMedium,
                color: AppColor.darkTitle,
              ),
            ],
          ),
          22.height,

          // 🔹 Notes Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(AppAssets.note, height: ResSize.h * 24),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: "Notes",
                      color: AppColor.subtitle,
                      fontSize: 10,
                      fontWeight: fwMedium,
                    ),

                    // ✅ Show either Text or nothing if editing
                    if (!showTextField)
                      TextWidget(
                        text: noteText,
                        color: AppColor.title,
                        fontSize: 14,
                        fontWeight: fwMedium,
                      ),
                  ],
                ),
              ),
              12.width,

              // 🔹 Edit button
              GestureDetector(
                onTap: () {
                  setState(() {
                    showTextField = true;
                    _noteController.text = noteText; // preload
                  });
                },
                child: Image.asset(AppAssets.edit, height: ResSize.h * 20),
              ),
            ],
          ),

          // 🔹 CustomTextField (only when editing)
          if (showTextField)
            Column(
              children: [
                8.height,
                SizedBox(
                  height: ResSize.h * 65,
                  child: customTextfield(
                    controller: _noteController,
                    borderColor: Colors.transparent,
                    borderWidth: 0,
                    fillColor: AppColor.liteBlue,
                    hint: "Enter your notes...",
                    borderRadius: 10,
                    maxline: 3,
                    contentVertPadding: 9,
                    contentHorizPadding: 7,
                    fontSize: 12,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (value) {
                      setState(() {
                        noteText = _noteController.text.isEmpty
                            ? "You have not added any notes"
                            : _noteController.text;
                        showTextField = false;
                      });
                      widget.session?.captureNote(
                        _noteController.text.trim(),
                      );
                    },
                  ),
                ),
              ],
            ),

          19.height,
          // 🔹 Promotions
          Container(
            height: ResSize.h * 40,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xffF5F4F1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: ResSize.w * 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextWidget(
                    text: "Promotions ",
                    color: AppColor.title,
                    fontSize: 12,
                    fontWeight: fwSemiBold,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: AppColor.green,
                        size: ResSize.h * 18,
                      ),
                      4.width,
                      TextWidget(
                        text: "ADD PROMO",
                        color: AppColor.green,
                        fontSize: 10,
                        fontWeight: fwSemiBold,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ✅ Rest of your code untouched
          16.height,
          SizedBox(
            height: ResSize.h * 50,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
                      color: AppColor.liteBlue,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: ResSize.w * 14),
                      child: Row(
                        children: [
                          Image.asset(
                            AppAssets.totalAmount,
                            height: ResSize.h * 22,
                          ),
                          8.width,
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextWidget(
                                  text: "total amount",
                                  color: AppColor.subtitle,
                                  fontSize: 12,
                                  fontWeight: fwSemiBold,
                                ),
                                TextWidget(
                                  text: "\$250.75",
                                  color: AppColor.green,
                                  fontSize: 14,
                                  fontWeight: fwSemiBold,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                2.width,
                Expanded(
                  child: InkWell(
                    onTap: () {
                      final typed = _noteController.text.trim();
                      setState(() {
                        noteText = typed.isEmpty
                            ? "You have not added any notes"
                            : typed;
                        showTextField = false;
                      });
                      widget.session?.captureNote(
                        typed.isEmpty ? '' : typed,
                      );
                      widget.onConfirm();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        color: AppColor.primary,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextWidget(
                                text: "CONTINUE",
                                color: AppColor.whiteText,
                                fontSize: 14,
                                fontWeight: fwSemiBold,
                              ),
                              6.width,
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppColor.white,
                                size: ResSize.h * 14,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          22.height,
        ],
      ),
    );
  }
}
