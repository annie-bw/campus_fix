import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/common.dart';
import 'auth_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final error = await context.read<AuthProvider>().sendPasswordReset(_email.text);
    if (!mounted) return;
    // Don't reveal whether an account exists: show the same message for
    // "user-not-found" as for success.
    if (error != null && !error.contains('incorrect')) {
      showAppSnack(context, error, error: true);
      return;
    }
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AuthProvider, bool>((a) => a.busy);

    return AuthScaffold(
      children: [
        const AuthHeading(
          title: 'Reset password',
          subtitle: 'Enter your ALU email and we’ll send you a link to set a new password.',
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: AppTextField(
            label: 'ALU email',
            controller: _email,
            hint: 'name@alustudent.com',
            prefixIcon: PhosphorIconsRegular.envelopeSimple,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: _sent ? 'Send again' : 'Send reset link',
          loading: busy,
          loadingLabel: 'Sending…',
          onPressed: _submit,
        ),
        if (_sent) ...[
          const SizedBox(height: 24),
          const NoticeBanner(
            icon: PhosphorIconsRegular.check,
            text: 'If an account exists for this email, a reset link is on its way. Check your inbox.',
          ),
        ],
      ],
    );
  }
}
