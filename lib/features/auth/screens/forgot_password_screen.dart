import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../state/auth_provider.dart';

/// Password recovery: step 1 requests an OTP, step 2 sets the new password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _identifier = TextEditingController();
  final TextEditingController _otp = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _otpSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toggleError(String? message) => setState(() => _error = message);

  /// Asks the backend to email an OTP to the account behind this identifier.
  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final bool sent = await context.read<AuthProvider>().requestPasswordReset(
      _identifier.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _otpSent = sent;
      _error = sent ? null : context.read<AuthProvider>().error;
    });
  }

  Future<void> _reset() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final bool updated = await context.read<AuthProvider>().setPassword(
      phone: _identifier.text.trim(),
      code: _otp.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = updated ? null : context.read<AuthProvider>().error;
    });
    if (!updated) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password updated. Sign in with the new password.'),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final String otp = _otp.text.trim();

    return AppScaffold(
      appBar: const AppTopBar(title: 'Reset password'),
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
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: context.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                size: 28,
                color: context.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _otpSent ? 'Enter the code' : 'Forgot your password?',
              style: texts.headline,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _otpSent
                  ? 'We sent a 6-digit code to the mobile number linked to your account.'
                  : 'Enter your registered mobile number or email and we will send a reset code.',
              style: texts.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_error != null) ...<Widget>[
              ErrorBanner(
                message: _error!,
                onDismiss: () => _toggleError(null),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (!_otpSent) ...<Widget>[
              const RequiredLabel(text: 'Mobile number or email'),
              AppTextField(
                controller: _identifier,
                label: 'Mobile number or email',
                hint: '9876543210 or you@email.com',
                prefixIcon: Icons.alternate_email_rounded,
                enabled: !_busy,
                validator: (String? value) {
                  final String v = (value ?? '').trim();
                  if (v.isEmpty) return 'Enter your mobile number or email';
                  if (v.contains('@')) return Validators.email(v);
                  return Validators.phone(v);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Send reset code',
                icon: Icons.sms_rounded,
                loading: _busy,
                onPressed: _busy ? null : _sendOtp,
              ),
            ] else ...<Widget>[
              const RequiredLabel(text: 'Reset code'),
              AppTextField(
                controller: _otp,
                label: '6-digit code',
                hint: 'Enter the code sent to you',
                prefixIcon: Icons.pin_rounded,
                keyboardType: TextInputType.number,
                maxLength: 6,
                enabled: !_busy,
                inputFormatters: <TextInputFormatter>[
                  DigitsOnlyFormatter(maxLength: 6),
                ],
                validator: Validators.otp,
                onChanged: (String _) =>
                    _error == null ? null : _toggleError(null),
              ),
              const SizedBox(height: AppSpacing.md),
              const RequiredLabel(text: 'New password'),
              AppTextField(
                controller: _password,
                label: 'New password',
                hint: 'At least 8 characters with a number',
                prefixIcon: Icons.lock_outline_rounded,
                obscure: true,
                enabled: !_busy,
                validator: Validators.password,
              ),
              const SizedBox(height: AppSpacing.md),
              const RequiredLabel(text: 'Confirm new password'),
              AppTextField(
                controller: _confirm,
                label: 'Confirm new password',
                hint: 'Re-enter the new password',
                prefixIcon: Icons.lock_reset_rounded,
                obscure: true,
                enabled: !_busy,
                onSubmitted: (_) => _reset(),
                validator: (String? value) =>
                    Validators.confirmPassword(value, _password.text),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Update password',
                icon: Icons.check_rounded,
                loading: _busy,
                onPressed: _busy
                    ? null
                    : () {
                        if (otp.isEmpty) {
                          _toggleError('Enter the 6-digit reset code');
                          return;
                        }
                        _reset();
                      },
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : _sendOtp,
                  child: const Text('Resend code'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
