import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum IconButtonVariant { soft, outline, white }

/// 44×44 icon button used for back / bell / filter / more actions.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = IconButtonVariant.soft,
    this.round = false,
    this.badge = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final IconButtonVariant variant;
  final bool round;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final bg = variant == IconButtonVariant.soft ? AppColors.surfaceSoft : Colors.white;
    final side = variant == IconButtonVariant.outline
        ? const BorderSide(color: AppColors.border)
        : BorderSide.none;

    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: bg,
            shape: round
                ? CircleBorder(side: side)
                : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: side),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(icon, size: 22, color: AppColors.ink, semanticLabel: tooltip),
              ),
            ),
          ),
          if (badge > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
