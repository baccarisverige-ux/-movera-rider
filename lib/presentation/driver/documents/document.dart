// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class DriverDocuments extends StatelessWidget {
  const DriverDocuments({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.secondary,
      body: Column(
        children: [
          55.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: ResSize.h * 20,
                  color: AppColor.primary,
                ),
              ),
              TextWidget(
                text: "Document",
                color: AppColor.primary,
                fontSize: 18,
                fontWeight: fwSemiBold,
              ),
              IconButton(
                onPressed: () {},
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                icon: SizedBox(),
              ),
            ],
          ),
          32.height,
          // Document List
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: ResSize.w * 20),
                child: Column(
                  children: [
                    // Driving Licence
                    _buildDocumentCard(
                      title: "Driving Licence",
                      expiryDate: "Expire in: 23 Sep, 2025",
                      status: DocumentStatus.verified,
                    ),

                    24.height,

                    // DBS Certificate
                    _buildDocumentCard(
                      title: "DBS Certificate",
                      expiryDate: "Expire in: 23 Sep, 2025",
                      status: DocumentStatus.verified,
                    ),

                    24.height,

                    // Vehicle Licence
                    _buildDocumentCard(
                      title: "Vehicle Licence",
                      expiryDate: "Expire in: 23 Sep, 2025",
                      status: DocumentStatus.expired,
                    ),

                    24.height,

                    // Insurance
                    _buildDocumentCard(
                      title: "Insurance",
                      expiryDate: "Expire in: 23 Sep, 2025",
                      status: DocumentStatus.pending,
                    ),

                    20.height,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String expiryDate,
    required DocumentStatus status,
  }) {
    return Container(
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
          // Title and Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextWidget(
                text: title,
                fontSize: 18,
                fontWeight: fwSemiBold,
                color: AppColor.primary,
              ),
              _buildStatusBadge(status),
            ],
          ),
          12.height,
          Divider(color: const Color(0xFFE0E0E0), thickness: 1, height: 1),
          12.height,
          // Expiry Date
          Row(
            children: [
              Image.asset(
                AppAssets.calendar,
                color: AppColor.subtitle,
                height: ResSize.h * 20,
              ),
              8.width,
              SizedBox(
                height: ResSize.h * 24,
                child: VerticalDivider(thickness: 0.8, color: AppColor.border),
              ),
              8.width,
              TextWidget(
                text: expiryDate,
                fontSize: 14,
                fontWeight: fwMedium,
                color: AppColor.subtitle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(DocumentStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case DocumentStatus.verified:
        backgroundColor = AppColor.green.withOpacity(0.2);
        textColor = AppColor.green;
        text = "Verified";
        break;
      case DocumentStatus.expired:
        backgroundColor = AppColor.red.withOpacity(0.2);
        textColor = AppColor.red;
        text = "Expired";
        break;
      case DocumentStatus.pending:
        backgroundColor = AppColor.yellow.withOpacity(0.2);
        textColor = AppColor.yellow;
        text = "Pending";
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResSize.w * 16,
        vertical: ResSize.h * 7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor, width: 1.5),
      ),
      child: TextWidget(
        text: text,
        fontSize: 14,
        fontWeight: fwMedium,
        color: textColor,
      ),
    );
  }
}

enum DocumentStatus { verified, expired, pending }
