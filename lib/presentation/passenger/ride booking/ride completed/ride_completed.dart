// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/presentation/passenger/bottom%20navigation/bottom_navigation.dart';
import 'package:riding_app/widgets/custom_btn.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/custom_textfield.dart';
import 'package:riding_app/widgets/navigation_transition.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class PassengerRideCompleted extends StatefulWidget {
  const PassengerRideCompleted({super.key});

  @override
  State<PassengerRideCompleted> createState() => _PassengerRideCompletedState();
}

class _PassengerRideCompletedState extends State<PassengerRideCompleted> {
  double rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  List<String> reviews = ["Polite", "Clean Car", "Car Driving", "Late"];

  @override
  Widget build(BuildContext context) {
    List<bool> selectedReviews = List.generate(reviews.length, (index) {
      return false;
    });
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: ResSize.w * 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              50.height,
              Center(
                child: TextWidget(
                  text: "Ride Completed",
                  fontSize: 18,
                  fontWeight: fwSemiBold,
                  color: AppColor.primary,
                ),
              ),
              24.height,
              // Fare Summary Section
              Container(
                padding: EdgeInsets.all(ResSize.w * 16),
                decoration: BoxDecoration(
                  color: AppColor.secondary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 5),
                      color: Color(0xff000000).withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: "Fare Summary",
                      fontSize: 18,
                      fontWeight: fwSemiBold,
                      color: AppColor.primary,
                    ),
                    14.height,
                    _buildFareRow("Base Fare", "\$10.00"),
                    14.height,
                    _buildFareRow("Distance", "\$10.00"),
                    14.height,
                    _buildFareRow("Time", "\$10.00"),
                    14.height,
                    _buildFareRow("Tax", "\$10.00"),
                    14.height,
                    _buildFareRow("Discount", "\$1.00"),
                    16.height,
                    Divider(color: AppColor.border, thickness: 1),
                    14.height,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextWidget(
                          text: "Total Fare",
                          fontSize: 16,
                          fontWeight: fwMedium,
                          color: Color(0xff4A4A4A),
                        ),
                        TextWidget(
                          text: "\$30.00",
                          fontSize: 16,
                          fontWeight: fwMedium,
                          color: Color(0xff4A4A4A),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              24.height,

              // Driver Info Section
              Container(
                padding: EdgeInsets.all(ResSize.w * 16),
                decoration: BoxDecoration(
                  color: AppColor.secondary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 5),
                      color: Color(0xff000000).withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Driver Avatar
                        Container(
                          width: ResSize.w * 51,
                          height: ResSize.w * 51,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage(AppAssets.profile),
                            ),
                          ),
                        ),
                        8.width,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWidget(
                                text: "Morgan Mill",
                                fontSize: 16,
                                fontWeight: fwMedium,
                                color: AppColor.primary,
                              ),
                              4.height,
                              Row(
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: ResSize.h * 18,
                                  ),
                                  4.width,
                                  TextWidget(
                                    text: "4.8",
                                    color: AppColor.subtitle,
                                    fontSize: 14,
                                    fontWeight: fwNormal,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    16.height,
                    // Vehicle Info Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              text: "L - 2323 F",
                              fontSize: 20,
                              fontWeight: fwSemiBold,
                              color: AppColor.primary,
                            ),
                            4.height,
                            TextWidget(
                              text: "Toyota HR-V",
                              fontSize: 14,
                              fontWeight: fwMedium,
                              color: AppColor.subtitle,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              text: "Standard",
                              fontSize: 16,
                              fontWeight: fwMedium,
                              color: AppColor.primary,
                            ),
                            2.height,
                            TextWidget(
                              text: "up to 4 seats",
                              fontSize: 14,
                              fontWeight: fwNormal,
                              color: AppColor.subtitle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              24.height,

              // Payment Method Section
              TextWidget(
                text: "Payment Method",
                fontSize: 18,
                fontWeight: fwSemiBold,
                color: AppColor.primary,
              ),
              16.height,
              customTextfield(
                keyboardType: TextInputType.number,
                hint: "3445  6464  7885  3321",
                prefixWidget: Padding(
                  padding: EdgeInsets.only(
                    left: ResSize.w * 12,
                    right: ResSize.w * 5,
                  ),
                  child: Image.asset(
                    AppAssets.visa,
                    height: ResSize.h * 20,
                    width: ResSize.w * 40,
                  ),
                ),
                suffixWidget: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColor.hintText,
                  size: ResSize.h * 18,
                ),
              ),

              24.height,

              // Rate Driver Section
              TextWidget(
                text: "Rate Driver",
                fontSize: 18,
                fontWeight: fwBold,
                color: Colors.black,
              ),
              16.height,
              Container(
                padding: EdgeInsets.all(ResSize.w * 16),
                decoration: BoxDecoration(
                  color: AppColor.secondary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 5),
                      color: Color(0xff000000).withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Rating Stars
                    Center(
                      child: Column(
                        children: [
                          TextWidget(
                            text: "Rate your driver",
                            fontSize: 16,
                            fontWeight: fwMedium,
                            color: AppColor.subtitle,
                          ),
                          SizedBox(height: ResSize.h * 16),
                          RatingBar.builder(
                            initialRating: 0,
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: false,
                            itemCount: 5,
                            itemSize: ResSize.w * 50,
                            unratedColor: Colors.grey.shade400,
                            itemPadding: EdgeInsets.symmetric(
                              horizontal: ResSize.w * 4,
                            ),
                            itemBuilder: (context, _) => const Icon(
                              Icons.star,
                              color: Color(0xFFFAC22F),
                            ),
                            onRatingUpdate: (rating) {
                              setState(() {
                                rating = rating;
                              });
                            },
                          ),
                          16.height,
                          SizedBox(
                            height: ResSize.h * 40,
                            child: ListView.builder(
                              itemCount: reviews.length,
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: BouncingScrollPhysics(),
                              itemBuilder: (BuildContext context, int index) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    left: index == 0 ? 0 : ResSize.w * 10,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            selectedReviews[index] =
                                                !selectedReviews[index];
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: ResSize.w * 12,
                                            vertical: ResSize.h * 5,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            color:
                                                selectedReviews[index] == true
                                                ? AppColor.primary
                                                : Color(0xffF6F6F6),
                                          ),
                                          child: Center(
                                            child: TextWidget(
                                              text: reviews[index],
                                              color:
                                                  selectedReviews[index] == true
                                                  ? AppColor.secondary
                                                  : Color(0xff717171),
                                              fontSize: 14,
                                              fontWeight: fwNormal,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    24.height,

                    // Comment TextField
                    customTextfield(
                      hint: "Add a comment (Optional)",
                      contentVertPadding: 12,
                    ),

                    24.height,
                    // Submit Button
                    CustomButton(
                      centerContent: "Submit rating",
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          BottomToTopTransition(
                            const PassengerBottomNavigation(),
                          ),
                        );
                      },
                      fontSize: 16,
                    ),

                    2.height,

                    Center(
                      child: TextButton(
                        onPressed: () {
                          // Handle report issue
                        },
                        child: TextWidget(
                          text: "Report an issue",
                          fontSize: 16,
                          fontWeight: fwNormal,
                          color: AppColor.subtitle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: ResSize.h * 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFareRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextWidget(
          text: label,
          fontSize: 14,
          fontWeight: fwNormal,
          color: AppColor.subtitle,
        ),
        TextWidget(
          text: amount,
          fontSize: 14,
          fontWeight: fwNormal,
          color: AppColor.subtitle,
        ),
      ],
    );
  }
}
