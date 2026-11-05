import 'package:flutter/material.dart';
import '../../core/app_icons.dart';

import '../../core/theme/app_colors.dart';

/// Shared layout for the auth screens: scrollable padded column that
/// keeps the footer at the bottom on tall phones and scrolls on small ones.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.children,
    this.footer,
    this.showBack = true,
    this.center = false,
  });

  final List<Widget> children;
  final Widget? footer;
  final bool showBack;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - 36),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
                  children: [
                    if (showBack)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Material(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(PhosphorIconsRegular.arrowLeft, semanticLabel: 'Back'),
                            ),
                          ),
                        ),
                      ),
                    if (showBack) const SizedBox(height: 24),
                    ...children,
                    const Spacer(),
                    if (footer != null) ...[const SizedBox(height: 24), footer!],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, required this.subtitle, this.center = false});

  final String title;
  final String subtitle;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final align = center ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: align,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: align,
          style: const TextStyle(fontSize: 15, color: AppColors.muted, height: 1.5),
        ),
      ],
    );
  }
}

/// "Don't have an account? Sign up" style footer link.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({super.key, required this.prompt, required this.action, required this.onTap});

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(prompt, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          child: Text(action, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

/// Logo mark: white pin-check on a green rounded square.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40, this.inverted = false});

  final double size;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: inverted ? Colors.white : AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
          child: Icon(
            PhosphorIconsFill.mapPin,
            color: inverted ? AppColors.primary : Colors.white,
            size: size * 0.58,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'CampusFix',
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w700,
            color: inverted ? Colors.white : AppColors.ink,
          ),
        ),
      ],
    );
  }
}
