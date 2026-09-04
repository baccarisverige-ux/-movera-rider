// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/custom_textfield.dart';
import 'package:riding_app/widgets/dropdown.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class AdditionalInfoVehicleDetail extends StatefulWidget {
  const AdditionalInfoVehicleDetail({super.key});

  @override
  State<AdditionalInfoVehicleDetail> createState() =>
      _AdditionalInfoVehicleDetailState();
}

class _AdditionalInfoVehicleDetailState
    extends State<AdditionalInfoVehicleDetail> {
  // Controllers
  final TextEditingController _vehicleMakeController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehicleYearController = TextEditingController();
  final TextEditingController _vehicleColorController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();

  // Dropdown Data
  final List<String> vehicleMakes = [
    'Toyota',
    'Honda',
    'Suzuki',
    'Hyundai',
    'KIA',
  ];

  final List<String> vehicleModels = [
    'Corolla',
    'Civic',
    'City',
    'Swift',
    'Elantra',
  ];

  final List<String> vehicleYears = [
    '2016',
    '2017',
    '2018',
    '2019',
    '2020',
    '2021',
    '2022',
    '2023',
    '2024',
    '2025',
    '2026',
  ];

  final List<String> vehicleColors = [
    'White',
    'Black',
    'Silver',
    'Gray',
    'Blue',
    'Red',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: ResSize.w * 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget(
              text: "Vehicle Details",
              fontSize: 18,
              fontWeight: fwSemiBold,
              color: AppColor.primary,
            ),
            2.height,
            TextWidget(
              text: "Add your vehicle information",
              fontSize: 14,
              fontWeight: fwNormal,
              color: AppColor.subtitle,
            ),
            22.height,

            Container(
              padding: EdgeInsets.all(ResSize.w * 16),
              decoration: BoxDecoration(
                color: AppColor.secondary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 5),
                    color: const Color(0xff000000).withOpacity(0.08),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Vehicle Make
                  TextWidget(
                    text: "Vehicle Make",
                    fontSize: 16,
                    fontWeight: fwMedium,
                    color: AppColor.primary,
                  ),
                  8.height,
                  AppDropdownField(
                    controller: _vehicleMakeController,
                    hint: 'Select Make',
                    items: vehicleMakes,
                  ),

                  16.height,

                  /// Vehicle Model
                  TextWidget(
                    text: "Vehicle Model",
                    fontSize: 16,
                    fontWeight: fwMedium,
                    color: AppColor.primary,
                  ),
                  8.height,
                  AppDropdownField(
                    controller: _vehicleModelController,
                    hint: 'Select Model',
                    items: vehicleModels,
                  ),

                  16.height,

                  /// Vehicle Year
                  TextWidget(
                    text: "Vehicle Year",
                    fontSize: 16,
                    fontWeight: fwMedium,
                    color: AppColor.primary,
                  ),
                  8.height,
                  AppDropdownField(
                    controller: _vehicleYearController,
                    hint: 'Select Year',
                    items: vehicleYears,
                  ),

                  16.height,

                  /// Vehicle Color
                  TextWidget(
                    text: "Vehicle Colour",
                    fontSize: 16,
                    fontWeight: fwMedium,
                    color: AppColor.primary,
                  ),
                  8.height,
                  AppDropdownField(
                    controller: _vehicleColorController,
                    hint: 'Select Colour',
                    items: vehicleColors,
                  ),

                  16.height,

                  /// Plate Number
                  TextWidget(
                    text: "Plate Number",
                    fontSize: 16,
                    fontWeight: fwMedium,
                    color: AppColor.primary,
                  ),
                  8.height,
                  customTextfield(
                    controller: _plateNumberController,
                    hint: "ABC-123",
                    keyboardType: TextInputType.text,
                  ),
                ],
              ),
            ),

            40.height,
          ],
        ),
      ),
    );
  }
}
