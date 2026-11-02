import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/otp_input.dart';
import '../../../state/auth_provider.dart';

/// OTP verification: 6 boxes, 45s resend countdown, error + loading states.
///
/// Demo hint: any 6 digits work except `000000` (used to preview the error state).
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, this.phone});

  final String? phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _resendSeconds = 45;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _otp = '';
  String? _localError;
  bool _busy = false;
  int _secondsLeft = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _resendSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _resend() {
    context.read<AuthProvider>().resendOtp();
    setState(() {
      _localError = null;
      _otp = '';
    });
    _startTimer();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('OTP sent again')));
  }

  Future<void> _verify() {
    if (_otp.length != 6) {
      setState(() => _localError = 'Enter the 6-digit code');
      return Future<void>.value();
    }
    setState(() {
      _busy = true;
      _localError = null;
    });
    return _runVerification();
  }

  Future<void> _runVerification() async {
    final AuthProvider auth = context.read<AuthProvider>();
    final bool ok = await auth.verifyOtp(_otp);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      setState(() => _localError = auth.error ?? 'Incorrect OTP');
      return;
    }
    // There is no role to pick, so the stage now points straight at
    // profile setup. Drop the pushed register/OTP routes and let the
    // stage-driven RootGate show the next screen.
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final String phone =
        widget.phone ?? context.watch<AuthProvider>().user?.phone ?? '';
    final String masked = phone.length == 10
        ? '+91 ${phone.substring(0, 2)}••••${phone.substring(8)}'
        : 'your mobile number';

    return AppScaffold(
      appBar: const AppTopBar(title: 'Verify mobile'),
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read_rounded,
                size: 30,
                color: context.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Enter the code', style: texts.headline),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'We sent a 6-digit code to $masked. It expires in 10 minutes.',
              style: texts.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            OtpInput(
              errorText: _localError,
              onChanged: (String value) {
                if (_localError != null) setState(() => _localError = null);
                _otp = value;
              },
              onCompleted: (_) => _verify(),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Verify and continue',
              loading: _busy,
              onPressed: _busy ? null : _verify,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: _secondsLeft > 0
                  ? Text(
                      'Resend code in ${_secondsLeft}s',
                      style: texts.caption,
                    )
                  : TextButton.icon(
                      onPressed: _busy ? null : _resend,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Resend OTP'),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const InfoBanner(
              message:
                  'Demo: enter 123456 to verify, or any other code to see the error state.',
              icon: Icons.science_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
