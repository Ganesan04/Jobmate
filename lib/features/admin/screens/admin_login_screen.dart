import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../navigation/app_router.dart';
import '../../../state/admin_provider.dart';

/// Admin sign in — intentionally separate from the user auth flow.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final AdminProvider admin = context.read<AdminProvider>();
    final bool ok = await admin.signIn(
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!ok || !mounted) return;
    AppRouter.pushReplacement(context, AppRoutes.adminShell);
  }

  void _useDemo() {
    setState(() {
      _email.text = 'admin@jobmate.in';
      _password.text = 'admin123';
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final AdminProvider admin = context.watch<AdminProvider>();

    return AppScaffold(
      appBar: AppTopBar(
        title: 'Admin',
        onBack: () => AppRouter.popToRoot(context),
      ),
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
            Center(
              child: Column(
                children: <Widget>[
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.adminPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 34,
                      color: AppColors.adminPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Jobmate Admin', style: texts.headline),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Console access is restricted to platform staff.',
                    style: texts.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _email,
              label: 'Admin email',
              hint: 'admin@jobmate.in',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              enabled: !admin.busy,
              validator: (String? value) {
                final String email = (value ?? '').trim();
                if (email.isEmpty) return 'Email is required';
                if (!email.contains('@') || !email.contains('.')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _password,
              label: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: _obscure,
              enabled: !admin.busy,
              onSubmitted: (_) => _submit(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (String? value) =>
                  (value ?? '').length < 6 ? 'Password is too short' : null,
            ),
            if (admin.error != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              ErrorBanner(message: admin.error!),
            ],
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Sign in to console',
              icon: Icons.login_rounded,
              loading: admin.busy,
              onPressed: admin.busy ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: 'Use demo credentials',
              icon: Icons.science_rounded,
              onPressed: _useDemo,
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: TextButton(
                onPressed: () => AppRouter.popToRoot(context),
                child: const Text('Back to Jobmate app'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text('admin@jobmate.in / admin123', style: texts.caption),
            ),
          ],
        ),
      ),
    );
  }
}
