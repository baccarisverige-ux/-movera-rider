import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/rider/saved%20places/add%20place/search_location.dart/pickup_location.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class AddPlace extends StatelessWidget {
  const AddPlace({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Row(
          children: [
            16.width,
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
          ],
        ),
        title: TextWidget(
          text: "Add new address",
          color: AppColor.title,
          fontSize: 16,
          fontWeight: fwSemiBold,
        ),
        centerTitle: true,
        // actions: [
        //   TextWidget(
        //     text: "Delete",
        //     color: AppColor.title,
        //     fontSize: 12,
        //     fontWeight: fwNormal,
        //   ),
        //   16.width,
        // ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              16.height,
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColor.border, width: 0.5),
                  ),
                ),
                child: TextField(
                  style: GoogleFonts.poppins(
                    color: AppColor.title,
                    fontSize: 16,
                    fontWeight: fwNormal,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,

                    labelText: "Name",
                    labelStyle: GoogleFonts.poppins(
                      color: AppColor.subtitle,
                      fontSize: 14,
                      fontWeight: fwNormal,
                    ),
                  ),
                ),
              ),
              16.height,
              InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    BottomToTopTransition(RiderSearchPickupLocation()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColor.border, width: 0.5),
                    ),
                  ),
                  child: TextField(
                    enabled: false,
                    style: GoogleFonts.poppins(
                      color: AppColor.title,
                      fontSize: 16,
                      fontWeight: fwNormal,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: "Add location",
                      labelStyle: GoogleFonts.poppins(
                        color: AppColor.subtitle,
                        fontSize: 12,
                        fontWeight: fwNormal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
