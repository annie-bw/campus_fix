import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The ALU campus photo, cropped to fill its box.
class CampusPhoto extends StatelessWidget {
  const CampusPhoto({super.key, this.height, this.alignment = Alignment.center});

  final double? height;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppColors.campusImage,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      alignment: alignment,
      errorBuilder: (_, _, _) => Container(height: height, color: AppColors.primaryTint),
    );
  }
}
