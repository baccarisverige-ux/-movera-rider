// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'responsive_size.dart';

class CustomCheckBox extends StatelessWidget {
  final bool value;
  final VoidCallback? onPressed;
  const CustomCheckBox({super.key, this.onPressed, required this.value});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Container(
        height: ResSize.h * 18,
        width: ResSize.w * 18,
        decoration: BoxDecoration(
          border: value
              ? Border.all(color: Colors.transparent, width: 0)
              : Border.all(color: AppColor.primary, width: 1.2),
          borderRadius: BorderRadius.circular(2),
          color: value ? AppColor.primary : Colors.transparent,
        ),
        child: Center(
          child: value
              ? Icon(
                  Icons.done_rounded,
                  size: ResSize.h * 15,
                  color: AppColor.secondary,
                )
              : SizedBox(),
        ),
      ),
    );
  }
}
