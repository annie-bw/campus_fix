import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/common.dart';
import 'auth_scaffold.dart';
import 'sign_in_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final error = await context.read<AuthProvider>().register(_name.text, _email.text, _password.text);
    // On success the auth state becomes "unverified" and AuthGate shows
    // the Verify email screen.
    if (error != null && mounted) showAppSnack(context, error, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AuthProvider, bool>((a) => a.busy);

    return AuthScaffold(
      footer: AuthSwitchLink(
        prompt: 'Already have an account?',
        action: 'Sign in',
        onTap: () =>
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SignInScreen())),
      ),
      children: [
        const AuthHeading(title: 'Create account', subtitle: 'It takes less than a minute.'),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Full name',
                  controller: _name,
                  hint: 'Your full name',
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.name,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'ALU email',
                  controller: _email,
                  hint: 'name@alustudent.com',
                  helper: 'Only ALU emails can sign up.',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.aluEmail,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  controller: _password,
                  hint: 'At least 8 characters',
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.newPassword,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Create account',
          loading: busy,
          loadingLabel: 'Creating account…',
          onPressed: _submit,
        ),
      ],
    );
  }
}
