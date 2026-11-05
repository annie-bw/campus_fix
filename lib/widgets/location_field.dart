import 'package:flutter/material.dart';
import '../core/app_icons.dart';

import '../core/constants.dart';
import '../core/theme/app_colors.dart';
import 'app_text_field.dart';
import 'bottom_sheet_frame.dart';

/// "Where is it?" picker: a FormField that opens a bottom sheet with the
/// campus buildings, plus an optional free-text detail (room / floor).
class LocationField extends FormField<String> {
  LocationField({
    super.key,
    super.initialValue,
    super.validator,
    required ValueChanged<String> onChanged,
    bool required = false,
  }) : super(
         autovalidateMode: AutovalidateMode.onUserInteraction,
         builder: (state) {
           final hasError = state.hasError;
           final value = state.value;
           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               FieldLabel('Where is it?', required: required),
               const SizedBox(height: 6),
               Material(
                 color: hasError ? AppColors.errorFill : Colors.white,
                 shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(14),
                   side: BorderSide(color: hasError ? AppColors.errorBorder : AppColors.border, width: 1.5),
                 ),
                 clipBehavior: Clip.antiAlias,
                 child: InkWell(
                   onTap: () async {
                     final picked = await _pick(state.context, value);
                     if (picked != null) {
                       state.didChange(picked);
                       onChanged(picked);
                     }
                   },
                   child: SizedBox(
                     height: 52,
                     child: Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 14),
                       child: Row(
                         children: [
                           const Icon(PhosphorIconsRegular.mapPin, size: 20, color: AppColors.muted),
                           const SizedBox(width: 10),
                           Expanded(
                             child: Text(
                               value ?? 'Choose a building',
                               overflow: TextOverflow.ellipsis,
                               style: TextStyle(
                                 fontSize: 15,
                                 color: value == null ? AppColors.muted : AppColors.ink,
                               ),
                             ),
                           ),
                           const Icon(PhosphorIconsRegular.caretDown, color: AppColors.muted),
                         ],
                       ),
                     ),
                   ),
                 ),
               ),
               if (hasError) ...[const SizedBox(height: 6), FieldError(state.errorText!)],
             ],
           );
         },
       );

  static Future<String?> _pick(BuildContext context, String? current) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BottomSheetFrame(
        title: 'Where is it?',
        child: Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final loc in campusLocations)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const Icon(PhosphorIconsRegular.mapPin, color: AppColors.primary),
                  title: Text(loc, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  trailing: loc == current
                      ? const Icon(PhosphorIconsRegular.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, loc),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline error row (alert icon + message) used under custom fields.
class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(PhosphorIconsRegular.warningCircle, size: 16, color: AppColors.error),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.error, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
