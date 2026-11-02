import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../navigation/app_router.dart';
import '../../../state/auth_provider.dart';

/// Registration: name, mobile, email, password, confirm password and terms
/// consent. Continues to OTP verification.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _termsAccepted = false;
  bool _termsError = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final bool valid = _formKey.currentState?.validate() ?? false;
    if (!_termsAccepted) setState(() => _termsError = true);
    if (!valid || !_termsAccepted) return;

    final AuthProvider auth = context.read<AuthProvider>();
    final NavigatorState navigator = Navigator.of(context);
    final bool ok = await auth.register(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!ok) return;
    navigator.pushReplacementNamed(
      AppRoutes.otp,
      arguments: _phone.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      appBar: const AppTopBar(title: 'Create account'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          children: <Widget>[
            Text('Let\'s get you started', style: texts.headline),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'One account to find work and to hire. You can switch between '
              'the two any time from your profile.',
              style: texts.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (auth.error != null) ...<Widget>[
              ErrorBanner(message: auth.error!, onDismiss: auth.clearError),
              const SizedBox(height: AppSpacing.md),
            ],
            const RequiredLabel(text: 'Full name'),
            AppTextField(
              controller: _name,
              label: 'Full name',
              hint: 'e.g. Ravi Kumar',
              prefixIcon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              enabled: !auth.busy,
              validator: Validators.fullName,
            ),
            const SizedBox(height: AppSpacing.md),
            const RequiredLabel(text: 'Mobile number'),
            AppTextField(
              controller: _phone,
              label: 'Mobile number',
              hint: '10-digit mobile number',
              prefixIcon: Icons.phone_iphone_rounded,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: <TextInputFormatter>[
                DigitsOnlyFormatter(maxLength: 10),
              ],
              enabled: !auth.busy,
              validator: Validators.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            const RequiredLabel(text: 'Email address'),
            AppTextField(
              controller: _email,
              label: 'Email address',
              hint: 'you@email.com',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !auth.busy,
              validator: Validators.email,
            ),
            const SizedBox(height: AppSpacing.md),
            const RequiredLabel(text: 'Password'),
            AppTextField(
              controller: _password,
              label: 'Password',
              hint: 'At least 8 characters with a number',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
              textInputAction: TextInputAction.next,
              enabled: !auth.busy,
              helper:
                  'Use 8+ characters with at least one letter and one number',
              validator: Validators.password,
            ),
            const SizedBox(height: AppSpacing.md),
            const RequiredLabel(text: 'Confirm password'),
            AppTextField(
              controller: _confirm,
              label: 'Confirm password',
              hint: 'Re-enter your password',
              prefixIcon: Icons.lock_reset_rounded,
              obscure: true,
              textInputAction: TextInputAction.done,
              enabled: !auth.busy,
              onSubmitted: (_) => _submit(),
              validator: (String? value) =>
                  Validators.confirmPassword(value, _password.text),
            ),
            const SizedBox(height: AppSpacing.md),
            _TermsCheckbox(
              value: _termsAccepted,
              showError: _termsError,
              onChanged: (bool value) => setState(() {
                _termsAccepted = value;
                if (value) _termsError = false;
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Send OTP',
              icon: Icons.sms_rounded,
              loading: auth.busy,
              onPressed: auth.busy ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Already registered?', style: texts.bodyMedium),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.showError,
    required this.onChanged,
  });

  final bool value;
  final bool showError;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: value,
                    onChanged: (bool? next) => onChanged(next ?? false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'I agree to the Jobmate Terms of Service and Privacy Policy, and I consent to '
                      'my phone number and documents being verified.',
                      style: texts.caption,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 2),
            child: Text(
              'Please accept the terms to continue',
              style: texts.caption?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
