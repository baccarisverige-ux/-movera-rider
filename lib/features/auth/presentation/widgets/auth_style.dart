import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colours and type for the sign-in flow ("Moving to a new era").
///
/// Cool white ground, ink text and Movera green, matching the Rider app's
/// design review. Kept local to the auth feature so the rest of the app's
/// theme is untouched.
abstract final class AuthColors {
  static const ground = Color(0xFFEEF1E8);
  static const ink = Color(0xFF17221C);
  static const muted = Color(0xFF65716B);
  static const faint = Color(0xFF89948E);
  static const green = Color(0xFF147A50);
  static const deepGreen = Color(0xFF123F32);
  static const field = Color(0xFFF1F4F2);
  static const line = Color(0xFFE1E7E3);
  static const stepIdle = Color(0xFFDDE5DF);
  static const stepDone = Color(0xFF9BBEAA);
  static const noteGround = Color(0xFFEDF5F0);
  static const noteText = Color(0xFF3B5A49);
  static const error = Color(0xFFB3261E);
  static const disabled = Color(0xFFE4E9E5);
  static const disabledText = Color(0xFF9CA9A1);
}

abstract final class AuthText {
  static TextStyle headline(double size) => GoogleFonts.poppins(
        fontSize: size,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
        color: AuthColors.ink,
      );

  static TextStyle lede() => GoogleFonts.poppins(
        fontSize: 15,
        height: 1.45,
        color: AuthColors.muted,
      );

  static TextStyle cardTitle() => GoogleFonts.poppins(
        fontSize: 17,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: AuthColors.ink,
      );

  static TextStyle cardSub() => GoogleFonts.poppins(
        fontSize: 13.5,
        height: 1.4,
        color: AuthColors.muted,
      );

  static TextStyle label() => GoogleFonts.poppins(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AuthColors.ink,
      );

  static TextStyle input() => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AuthColors.ink,
      );

  static TextStyle small() => GoogleFonts.poppins(
        fontSize: 12,
        height: 1.45,
        color: AuthColors.faint,
      );
}
