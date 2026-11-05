import 'package:flutter/material.dart';
import '../core/app_icons.dart';

import '../core/theme/app_colors.dart';

class NavItem {
  const NavItem(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Bottom bar from the design. Students get a raised green "+" in the
/// middle for a new report; staff get three plain tabs.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.onFab,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onFab; // null = no centre button (staff)

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (onFab != null && i == items.length - 1) children.add(_Fab(onTap: onFab!));
      children.add(
        Expanded(
          child: _Tab(item: items[i], active: i == currentIndex, onTap: () => onTap(i)),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.active, required this.onTap});

  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.muted;
    return Semantics(
      selected: active,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              Icon(active ? item.activeIcon : item.icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11.5,
                  color: color,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OverflowBox(
        maxHeight: 100,
        alignment: Alignment.topCenter,
        child: Transform.translate(
          offset: const Offset(0, -24),
          child: Semantics(
            button: true,
            label: 'New report',
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x4D15803D), blurRadius: 16, offset: Offset(0, 6)),
                  ],
                ),
                child: const Icon(PhosphorIconsRegular.plus, color: Colors.white, size: 30),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
