import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

import 'package:syncfusion_flutter_datepicker/datepicker.dart';
// ignore: depend_on_referenced_packages

class CustomDatePicker extends StatelessWidget {
  final DateRangePickerController controller;
  const CustomDatePicker({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          22.height,
          SfDateRangePicker(
            controller: controller,
            backgroundColor: Colors.transparent,
            navigationDirection: DateRangePickerNavigationDirection.horizontal,
            showNavigationArrow: true,
            selectionColor: AppColor.primary,
            monthCellStyle: DateRangePickerMonthCellStyle(
              textStyle: GoogleFonts.poppins(
                fontSize: ResSize.setSp(14),
                fontWeight: fwMedium,
                color: AppColor.black,
              ),
            ),
            headerStyle: DateRangePickerHeaderStyle(
              textAlign: TextAlign.center,
              textStyle: GoogleFonts.poppins(
                color: AppColor.black,
                fontSize: ResSize.setSp(16),
                fontWeight: fwBold,
              ),
              backgroundColor: Colors.transparent,
            ),
            selectionTextStyle: GoogleFonts.poppins(
              color: AppColor.whiteText,
              fontWeight: fwMedium,
              fontSize: ResSize.setSp(14),
            ),
            monthViewSettings: DateRangePickerMonthViewSettings(
              viewHeaderStyle: DateRangePickerViewHeaderStyle(
                textStyle: GoogleFonts.poppins(
                  fontSize: ResSize.setSp(13),
                  fontWeight: fwBold,
                  color: AppColor.black,
                ),
              ),
            ),
            todayHighlightColor: AppColor.primary,
            selectionMode: DateRangePickerSelectionMode.single,
            initialSelectedDate: controller.selectedDate ?? DateTime.now(),
          ),
        ],
      ),
    );
  }
}
