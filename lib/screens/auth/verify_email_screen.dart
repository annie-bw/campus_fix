import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/common.dart';
import 'auth_scaffold.dart';

/// Shown while the signed-in account has not verified its ALU email.
/// The app itself (and Firestore, via security rules) stays locked until
/// the link in the email is opened.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  // Cool-down so the resend button can't spam Firebase (rate limited).
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) t.cancel();
      if (mounted) setState(() => _cooldown--);
    });
  }

  Future<void> _resend() async {
    final error = await context.read<AuthProvider>().resendVerification();
    if (!mounted) return;
    if (error != null) {
      showAppSnack(context, error, error: true);
    } else {
      showAppSnack(context, 'Verification link sent again.');
      _startCooldown();
    }
  }

  Future<void> _check() async {
    final error = await context.read<AuthProvider>().checkVerified();
    if (error != null && mounted) showAppSnack(context, error, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthScaffold(
      showBack: false,
      center: true,
      footer: Column(
        children: [
          AppButton(
            label: 'I’ve verified my email',
            loading: auth.busy,
            loadingLabel: 'Checking…',
            onPressed: _check,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: _cooldown > 0 ? 'Resend link (${_cooldown}s)' : 'Resend link',
            variant: AppButtonVariant.ghost,
            onPressed: _cooldown > 0 || auth.busy ? null : _resend,
          ),
          TextButton(
            onPressed: auth.signOut,
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            child: const Text('Use a different account'),
          ),
        ],
      ),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
            child: const Icon(PhosphorIconsRegular.envelopeSimple, size: 40, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Check your email',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'We sent a verification link to\n',
            children: [
              TextSpan(
                text: auth.email,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, height: 1.55, color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        const NoticeBanner(
          icon: PhosphorIconsRegular.info,
          tone: NoticeTone.gray,
          text: 'Can’t find it? Check your spam or junk folder. The link opens in your browser.',
        ),
      ],
    );
  }
}
