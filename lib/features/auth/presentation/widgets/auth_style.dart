import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colours and type for the sign-in flow ("Moving to a new era").
///
/// Cream ground, ink text and Movera green, as approved in the sign-in
/// design review. Kept local to the auth feature so the rest of the app's
/// theme is untouched.
abstract final class AuthColors {
  static const ground = Color(0xFFFAF7F0);
  static const ink = Color(0xFF121A16);
  static const muted = Color(0xFF5F6862);
  static const faint = Color(0xFF8A918B);
  static const green = Color(0xFF12804F);
  static const deepGreen = Color(0xFF0F3B2D);
  static const field = Color(0xFFF6F4EE);
  static const line = Color(0xFFECE8DE);
  static const stepIdle = Color(0xFFE4DFD2);
  static const stepDone = Color(0xFF8DB9A0);
  static const noteGround = Color(0xFFF0F6F2);
  static const noteText = Color(0xFF3F5A4B);
  static const error = Color(0xFFB3261E);
  static const disabled = Color(0xFFECE9E0);
  static const disabledText = Color(0xFFA7AAA2);
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
