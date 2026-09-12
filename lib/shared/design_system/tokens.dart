import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';

/// Frozen Movera tokens. Do not invent a second palette.
abstract final class MoveraTokens {
  static const Color ink = Color(0xFF1D252C);
  static const Color accent = Color(0xFF2D5878);
  static const Color cta = Color(0xFF11181D);
  static const Color bg = AppColor.bg;
  static const Color line = Color(0xFFE7EBEE);
  static const Color muted = Color(0xFF7B8388);
  static const double radiusSheet = 28;
  static const double buttonHeight = 56;
  static const Duration motion = Duration(milliseconds: 220);
}
