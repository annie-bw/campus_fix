import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/common.dart';
import 'auth_scaffold.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final error = await context.read<AuthProvider>().signIn(_email.text, _password.text);
    // On success AuthGate swaps to the app automatically.
    if (error != null && mounted) showAppSnack(context, error, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AuthProvider, bool>((a) => a.busy);

    return AuthScaffold(
      footer: AuthSwitchLink(
        prompt: 'Don’t have an account?',
        action: 'Sign up',
        onTap: () =>
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RegisterScreen())),
      ),
      children: [
        const BrandMark(),
        const SizedBox(height: 40),
        const AuthHeading(title: 'Welcome back', subtitle: 'Sign in with your ALU email.'),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Email',
                  controller: _email,
                  hint: 'name@alustudent.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email, // staff may use a non-ALU email
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  controller: _password,
                  hint: 'Your password',
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: Validators.password,
                  onSubmitted: (_) => _submit(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ForgotPasswordScreen(initialEmail: _email.text)),
                    ),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppButton(label: 'Sign in', loading: busy, loadingLabel: 'Signing in…', onPressed: _submit),
      ],
    );
  }
}
