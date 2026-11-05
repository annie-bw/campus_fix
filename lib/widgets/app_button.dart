import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum AppButtonVariant { primary, outline, white, danger, ghost, destructive }

/// Full-width button from the design (54px, radius 14). Shows a spinner and
/// [loadingLabel] while [loading] is true and ignores taps meanwhile.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.small = false,
    this.loading = false,
    this.loadingLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool small;
  final bool loading;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      AppButtonVariant.primary => (AppColors.primary, Colors.white, AppColors.primary),
      AppButtonVariant.outline => (Colors.white, AppColors.primary, AppColors.primary),
      AppButtonVariant.white => (Colors.white, AppColors.primary, Colors.white),
      AppButtonVariant.danger => (AppColors.errorFill, AppColors.error, AppColors.errorOutline),
      AppButtonVariant.ghost => (Colors.transparent, AppColors.primary, Colors.transparent),
      AppButtonVariant.destructive => (AppColors.destructive, Colors.white, AppColors.destructive),
    };
    final height = small ? 42.0 : 54.0;
    final disabled = onPressed == null && !loading;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(small ? 12 : 14),
            side: BorderSide(color: border, width: variant == AppButtonVariant.danger ? 1 : 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: loading ? null : onPressed,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
                    )
                  else if (icon != null)
                    Icon(icon, size: 18, color: fg),
                  if (loading || icon != null) const SizedBox(width: 8),
                  Text(
                    loading ? (loadingLabel ?? label) : label,
                    style: TextStyle(color: fg, fontSize: small ? 14 : 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
