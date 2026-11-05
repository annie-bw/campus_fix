import 'package:flutter/material.dart';
import '../core/app_icons.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/shell_provider.dart';
import 'app_shell.dart';
import 'auth/verify_email_screen.dart';
import 'auth/welcome_screen.dart';

/// Root widget that picks what to show from the auth state:
/// signed out → Welcome, unverified → Verify email, signed in → AppShell.
/// When the state changes, any pushed screens (sign in, register, details)
/// are popped so the user never sees a stale screen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthStatus? _last;

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((a) => a.status);

    if (_last != null && _last != status) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.navigatorKey.currentState?.popUntil((r) => r.isFirst);
      });
      if (status == AuthStatus.signedIn) context.read<ShellProvider>().reset();
    }
    _last = status;

    return switch (status) {
      AuthStatus.unknown => const _Splash(),
      AuthStatus.signedOut => const WelcomeScreen(),
      AuthStatus.unverified => const VerifyEmailScreen(),
      AuthStatus.signedIn => const AppShell(),
    };
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsFill.mapPin, color: Colors.white, size: 56),
            SizedBox(height: 12),
            Text(
              'CampusFix',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
