// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/models/image_title.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class AdditionalInfoUploadDocument extends StatefulWidget {
  const AdditionalInfoUploadDocument({super.key});

  @override
  State<AdditionalInfoUploadDocument> createState() =>
      _AdditionalInfoUploadDocumentState();
}

class _AdditionalInfoUploadDocumentState
    extends State<AdditionalInfoUploadDocument> {
  List<ImageTitleModel> documents = [
    ImageTitleModel(image: AppAssets.drivingLicence, title: "Driving Licence"),
    ImageTitleModel(image: AppAssets.dbsCertificate, title: "DBS Certificate"),
    ImageTitleModel(
      image: AppAssets.privateHireLicence,
      title: "Private Hire Licence",
    ),
    ImageTitleModel(image: AppAssets.vehicleLicence, title: "Vehicle Licence"),
    ImageTitleModel(image: AppAssets.insurance, title: "Insurance"),
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
              text: "Upload Documents",
              fontSize: 18,
              fontWeight: fwSemiBold,
              color: AppColor.primary,
            ),
            2.height,
            TextWidget(
              text: "Required to activate your account",
              fontSize: 14,
              fontWeight: fwNormal,
              color: AppColor.subtitle,
            ),
            22.height,
            ListView.builder(
              itemCount: documents.length,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: index == 0 ? 0 : ResSize.h * 24,
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
                          horizontal: ResSize.w * 10,
                          vertical: ResSize.h * 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: ResSize.h * 44,
                              width: ResSize.w * 44,
                              decoration: BoxDecoration(
                                color: Color(0xffF4F4F4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Image.asset(
                                  documents[index].image,
                                  height: ResSize.h * 24,
                                  color: Color(0xff6B6B6B),
                                ),
                              ),
                            ),
                            10.width,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: documents[index].title,
                                    color: AppColor.primary,
                                    fontSize: 16,
                                    fontWeight: fwMedium,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: ResSize.h * 18,
                              color: Color(0xff6B6B6B),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            40.height,
          ],
        ),
      ),
    );
  }
}
