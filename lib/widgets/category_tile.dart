import 'package:flutter/material.dart';
import '../core/app_icons.dart';

import '../core/constants.dart';
import '../core/theme/app_colors.dart';

/// Square, selectable tile: an icon in a soft well with a small label.
/// Used for categories (report form, filters) and statuses (filters).
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.wellColor = AppColors.primaryTint,
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color wellColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.primary : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.selectedWell : wellColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: selected ? Colors.white : iconColor),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Category version of [IconTile].
class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category, required this.selected, required this.onTap});

  final IncidentCategory category;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) =>
      IconTile(icon: category.icon, label: category.label, selected: selected, onTap: onTap);
}

/// Fixed-height grid of tiles (96px each, as in the design).
class TileGrid extends StatelessWidget {
  const TileGrid({super.key, required this.children, this.columns = 3});

  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) => GridView(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      mainAxisExtent: 96,
    ),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.zero,
    children: children,
  );
}

/// The 6-tile grid with an inline error, wrapped as a FormField so it
/// takes part in Form.validate() like the text fields.
class CategoryPicker extends FormField<IncidentCategory> {
  CategoryPicker({
    super.key,
    super.initialValue,
    required ValueChanged<IncidentCategory> onChanged,
    bool enabled = true,
  }) : super(
         validator: (v) => v == null ? 'Please choose a category' : null,
         builder: (state) => Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             const Text('What kind of issue?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
             const SizedBox(height: 10),
             // Fixed 96px tile height (as in the design) on any screen width.
             GridView(
               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                 crossAxisCount: 3,
                 mainAxisSpacing: 10,
                 crossAxisSpacing: 10,
                 mainAxisExtent: 96,
               ),
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               children: [
                 for (final c in IncidentCategory.values)
                   CategoryTile(
                     category: c,
                     selected: state.value == c,
                     onTap: enabled
                         ? () {
                             state.didChange(c);
                             onChanged(c);
                           }
                         : null,
                   ),
               ],
             ),
             if (state.hasError) ...[
               const SizedBox(height: 8),
               Row(
                 children: [
                   const Icon(PhosphorIconsRegular.warningCircle, size: 16, color: AppColors.error),
                   const SizedBox(width: 6),
                   Text(
                     state.errorText!,
                     style: const TextStyle(
                       color: AppColors.error,
                       fontSize: 12.5,
                       fontWeight: FontWeight.w600,
                     ),
                   ),
                 ],
               ),
             ],
           ],
         ),
       );
}
