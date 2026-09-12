import 'package:flutter/material.dart';

class SafetyMarks {
  static const shield = 'assets/icons/safety_mark_shield.png';
  static const pin = 'assets/icons/safety_mark_pin.png';
  static const contacts = 'assets/icons/safety_mark_contacts.png';
  static const share = 'assets/icons/safety_mark_share.png';
  static const rideCheck = 'assets/icons/safety_mark_ridecheck.png';
  static const tips = 'assets/icons/safety_mark_tips.png';
  static const protect = 'assets/icons/safety_mark_protect.png';
}

class SafetyMark extends StatelessWidget {
  const SafetyMark(this.asset, {super.key, this.size = 44});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.high,
      fit: BoxFit.contain,
    );
  }
}
