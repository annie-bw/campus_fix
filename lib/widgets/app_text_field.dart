import 'package:flutter/material.dart';
import '../core/app_icons.dart';

import '../core/theme/app_colors.dart';

/// Shared input decoration so every field matches the design:
/// 52px tall, radius 14, green focus border, red error state.
InputDecoration appInputDecoration({String? hint, IconData? prefixIcon, Widget? suffix, String? helper}) {
  OutlineInputBorder border(Color c, [double w = 1.5]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.muted, fontSize: 15),
    helperText: helper,
    helperStyle: const TextStyle(color: AppColors.muted, fontSize: 12.5),
    helperMaxLines: 2,
    errorStyle: const TextStyle(color: AppColors.error, fontSize: 12.5, fontWeight: FontWeight.w600),
    errorMaxLines: 2,
    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, color: AppColors.muted, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    enabledBorder: border(AppColors.border),
    focusedBorder: border(AppColors.primary),
    errorBorder: border(AppColors.errorBorder),
    focusedErrorBorder: border(AppColors.errorBorder),
    disabledBorder: border(AppColors.border),
  );
}

/// Label above the field, with an optional red asterisk.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false, this.optional = false});

  final String text;
  final bool required;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error),
            ),
          if (optional)
            const TextSpan(
              text: ' (optional)',
              style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.obscure = false,
    this.multiline = false,
    this.required = false,
    this.enabled = true,
    this.maxLength,
    this.autofillHints,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final bool obscure;
  final bool multiline;
  final bool required;
  final bool enabled;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  // Local UI-only state (password visibility) is fine as setState.
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(widget.label, required: widget.required),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          enabled: widget.enabled,
          obscureText: _hidden,
          keyboardType: widget.multiline ? TextInputType.multiline : widget.keyboardType,
          textInputAction: widget.textInputAction,
          minLines: widget.multiline ? 4 : 1,
          maxLines: widget.multiline ? 6 : 1,
          maxLength: widget.maxLength,
          autofillHints: widget.autofillHints,
          onFieldSubmitted: widget.onSubmitted,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontSize: 15, color: AppColors.ink, height: 1.5),
          decoration: appInputDecoration(
            hint: widget.hint,
            helper: widget.helper,
            prefixIcon: widget.prefixIcon,
            suffix: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _hidden ? PhosphorIconsRegular.eye : PhosphorIconsRegular.eyeSlash,
                      color: AppColors.muted,
                    ),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
