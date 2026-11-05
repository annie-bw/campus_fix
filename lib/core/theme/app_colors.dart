import 'package:flutter/material.dart';

/// Colour tokens taken directly from the CampusFix design canvas.
/// Every widget reads colours from here so the palette stays consistent.
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF15803D);
  static const primaryDark = Color(0xFF14532D);
  static const primaryHover = Color(0xFF166534);
  static const primaryTint = Color(0xFFECF7EF); // icon wells, soft cards
  static const primaryTintStrong = Color(0xFFD7EFDF);
  static const primaryOnDark = Color(0xFFE3F4E8); // body text on green
  static const selectedWell = Color(0xFF1E9150);

  // Neutrals
  static const ink = Color(0xFF13261B);
  static const inkSoft = Color(0xFF2F4237);
  static const muted = Color(0xFF56675D);
  static const border = Color(0xFFDCE7E0);
  static const borderStrong = Color(0xFF9DBBA8);
  static const pending = Color(0xFFC5D3CA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF5F9F6);
  static const scrim = Color(0x7313261B); // rgba(19,38,27,0.45)
  static const canvas = Color(0xFFF3F7F4); // tab backgrounds behind white cards

  /// Campus photo (Social Commons) used on the landing page and Home.
  static const campusImage = 'assets/images/campus.jpg';

  // Feedback
  static const error = Color(0xFFA1281C);
  static const errorBorder = Color(0xFFC0392B);
  static const errorFill = Color(0xFFFFF8F7);
  static const errorTint = Color(0xFFFCE8E6);
  static const errorOutline = Color(0xFFF3C9C4);
  static const destructive = Color(0xFFB42318);

  // Status tones (background, foreground)
  static const blueBg = Color(0xFFEAF0FB);
  static const blueFg = Color(0xFF234A8F);
  static const grayBg = Color(0xFFEEF1F4);
  static const grayFg = Color(0xFF3D4A56);
  static const amberBg = Color(0xFFFFF2DB);
  static const amberFg = Color(0xFF8A5300);
  static const amberText = Color(0xFF6B4100);
  static const greenBg = Color(0xFFDFF3E5);
  static const greenFg = Color(0xFF136A35);
  static const redBg = Color(0xFFFCE8E6);
  static const redFg = Color(0xFFA1281C);
}
