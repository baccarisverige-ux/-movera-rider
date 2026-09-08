import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/rider/schedule%20ride/select%20date%20time/components/date_picker.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class ScheduleDateTimeSelector extends StatefulWidget {
  final VoidCallback onConfirm;
  final Widget body;
  const ScheduleDateTimeSelector({
    super.key,
    required this.body,
    required this.onConfirm,
  });

  @override
  State<ScheduleDateTimeSelector> createState() =>
      _ScheduleDateTimeSelectorState();
}

class _ScheduleDateTimeSelectorState extends State<ScheduleDateTimeSelector> {
  String selectedDate = "Jul 12, 25";
  String selectedTime = "10:30 AM";
  bool isDateSelected = false;
  bool isTimeSelected = false;
  void _showDatePicker(BuildContext context) async {
    final pickerController = DateRangePickerController()
      ..selectedDate = DateTime.now(); // default selection
    final pickedDateStr = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: false,
      builder: (ctx) {
        return Container(
          height: 420,
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              CustomDatePicker(controller: pickerController),
              const Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
                child: CustomButton(
                  centerContent: "Confirm Date",
                  onPressed: () {
                    final dt = pickerController.selectedDate ?? DateTime.now();
                    final formatted = DateFormat('dd/MM/yyyy').format(dt);
                    Navigator.pop(ctx, formatted); // return the date string
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
    if (pickedDateStr != null && pickedDateStr.isNotEmpty) {
      setState(() {
        selectedDate = pickedDateStr;
        isDateSelected = true; // show in your SlidingUpPanelWidget
      });
    }
  }

  // Open Time Picker
  Future<void> _showDateTimePicker() async {
    final TimeOfDay? timePicked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: TimeOfDay.now().hour,
        minute: TimeOfDay.now().minute,
      ),
    );
    if (timePicked != null) {
      setState(() {
        // Format to readable string like 10:30 AM
        final now = DateTime.now();
        final dt = DateTime(
          now.year,
          now.month,
          now.day,
          timePicked.hour,
          timePicked.minute,
        );
        selectedTime = DateFormat('hh:mm a').format(dt);
        isTimeSelected = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlidingUpPanel(
      color: AppColor.white,
      backdropColor: Colors.transparent,
      margin: EdgeInsets.all(0),
      minHeight: ResSize.h * 224,
      padding: EdgeInsets.symmetric(
        horizontal: screenHorizPadding,
        vertical: ResSize.h * 16,
      ),
      boxShadow: [],
      isDraggable: true,
      defaultPanelState: PanelState.CLOSED,
      maxHeight: ResSize.h * 224,
      parallaxEnabled: false,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      panelBuilder: (ScrollController sc) => panelColumn(),
      // panelBuilder: (ScrollController sc) => panelColumn(sc, context),
      body: widget.body,
    );
  }

  Widget panelColumn() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            fontSize: 12,
            fontWeight: fwSemiBold,
            text: "Schedule your ride",
            color: AppColor.subtitle,
          ),
          5.height,
          TextWidget(
            fontSize: 16,
            fontWeight: fwSemiBold,
            text: "Click to select dates",
            color: AppColor.green,
          ),
          20.height,
          Row(
            children: [
              dateTimeSelectorCard(
                icon: AppAssets.calendar2,
                title: "Select date",
                subtitle: selectedDate,
                onPressed: () => _showDatePicker(context),
              ),
              dateTimeSelectorCard(
                icon: AppAssets.time,
                title: "Select time",
                subtitle: selectedTime,
                onPressed: () => _showDateTimePicker(),
              ),
            ],
          ),
          19.height,
          CustomButton(
            centerContent: "Confirm",
            onPressed: () {
              widget.onConfirm();
            },
          ),
        ],
      ),
    );
  }

  Widget dateTimeSelectorCard({
    String? title,
    icon,
    subtitle,
    final VoidCallback? onPressed,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Row(
          children: [
            Container(
              height: ResSize.h * 35,
              width: ResSize.w * 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.liteGrey,
              ),
              child: Center(
                child: Image.asset(
                  icon,
                  color: AppColor.primary,
                  height: ResSize.h * 20,
                ),
              ),
            ),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    fontSize: 14,
                    fontWeight: fwSemiBold,
                    text: title,
                    color: AppColor.black,
                  ),
                  6.height,
                  TextWidget(
                    fontSize: 14,
                    fontWeight: fwMedium,
                    text: subtitle,
                    color:
                        (title == "Select date" && isDateSelected) ||
                            (title == "Select time" && isTimeSelected)
                        ? AppColor
                              .black // ✅ black when selected
                        : AppColor.subtitle, // gray before selection
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
