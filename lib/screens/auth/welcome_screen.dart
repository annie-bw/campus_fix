import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/campus_photo.dart';
import 'auth_scaffold.dart';
import 'register_screen.dart';
import 'sign_in_screen.dart';

/// Landing page: a campus photo on top, a short pitch and two actions.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final photoHeight = (media.size.height * 0.36).clamp(240.0, 380.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                child: CampusPhoto(height: photoHeight),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 28, 24, 20 + media.padding.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandMark(size: 32),
                    const SizedBox(height: 22),
                    const Text(
                      'Spot it. Report it.\nSee it fixed.',
                      style: TextStyle(
                        fontSize: 30,
                        height: 1.2,
                        letterSpacing: -0.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _Step(
                      PhosphorIconsRegular.eye,
                      'Spot an issue',
                      'A leak, an outage, a broken chair',
                    ),
                    const SizedBox(height: 14),
                    const _Step(
                      PhosphorIconsRegular.camera,
                      'Report it in a minute',
                      'Pick a category, add a photo',
                    ),
                    const SizedBox(height: 14),
                    const _Step(
                      PhosphorIconsRegular.check,
                      'See it fixed',
                      'Get updates as staff work on it',
                    ),
                    const SizedBox(height: 28),
                    AppButton(
                      label: 'Get started',
                      onPressed: () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'I already have an account',
                      variant: AppButtonVariant.ghost,
                      onPressed: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInScreen())),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
            ],
          ),
        ),
      ],
    );
  }
}
