import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../models/enums.dart';
import '../../../navigation/app_router.dart';
import '../../../state/auth_provider.dart';
import 'splash_screen.dart';

/// Sign-in screen: identifier + password, demo credential hint, error/loading
/// states, and links to register, forgot password and the admin console.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _identifier = TextEditingController(
    text: '9876543210',
  );
  final TextEditingController _password = TextEditingController(
    text: 'jobmate123',
  );

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final AuthProvider auth = context.read<AuthProvider>();
    await auth.signIn(
      identifier: _identifier.text.trim(),
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Align(
                alignment: Alignment.centerLeft,
                child: BrandMark(size: 46),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Welcome back', style: texts.display),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sign in to find work or hire workers near you.',
                style: texts.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (auth.error != null) ...<Widget>[
                ErrorBanner(message: auth.error!, onDismiss: auth.clearError),
                const SizedBox(height: AppSpacing.md),
              ],
              const RequiredLabel(text: 'Mobile number or email'),
              AppTextField(
                controller: _identifier,
                label: 'Mobile number or email',
                hint: '9876543210 or you@email.com',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                enabled: !auth.busy,
                validator: (String? value) {
                  final String v = (value ?? '').trim();
                  if (v.isEmpty) return 'Enter your mobile number or email';
                  if (v.contains('@')) return Validators.email(v);
                  return Validators.phone(v);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              const RequiredLabel(text: 'Password'),
              AppTextField(
                controller: _password,
                label: 'Password',
                hint: 'At least 8 characters',
                prefixIcon: Icons.lock_outline_rounded,
                obscure: true,
                textInputAction: TextInputAction.done,
                enabled: !auth.busy,
                onSubmitted: (_) => _submit(),
                validator: (String? value) {
                  final String? base = Validators.password(value);
                  if (base != null) return base;
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: auth.busy
                      ? null
                      : () => AppRouter.push(context, AppRoutes.forgotPassword),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                label: 'Sign in',
                icon: Icons.login_rounded,
                loading: auth.busy,
                onPressed: auth.busy ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('New to Jobmate?', style: texts.bodyMedium),
                  TextButton(
                    onPressed: auth.busy
                        ? null
                        : () => AppRouter.push(context, AppRoutes.register),
                    child: const Text('Create account'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _RoleSwitchCard(),
              const SizedBox(height: AppSpacing.md),
              _DemoHint(
                onAdminTap: () => AppRouter.push(context, AppRoutes.adminLogin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lets anyone jump straight into either role without signing in (demo helper).
class _RoleSwitchCard extends StatelessWidget {
  const _RoleSwitchCard();

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final TextTheme texts = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.bolt_rounded, size: 17, color: context.primary),
              const SizedBox(width: 6),
              Text('Try it as', style: texts.labelLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: _RoleButton(
                  role: UserRole.worker,
                  color: AppColors.workerPrimary,
                  icon: Icons.handyman_rounded,
                  isActive: auth.role == UserRole.worker,
                  onTap: () => auth.selectRole(UserRole.worker),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _RoleButton(
                  role: UserRole.workGiver,
                  color: AppColors.giverPrimary,
                  icon: Icons.business_center_rounded,
                  isActive: auth.role == UserRole.workGiver,
                  onTap: () => auth.selectRole(UserRole.workGiver),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Or tap a role above to jump straight into that home screen.',
            style: texts.caption,
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.role,
    required this.color,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final UserRole role;
  final Color color;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      child: Material(
        color: isActive
            ? Color.lerp(color, Colors.white, 0.9)
            : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isActive ? color : AppColors.border,
                width: isActive ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? color : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    role.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isActive ? color : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoHint extends StatelessWidget {
  const _DemoHint({required this.onAdminTap});

  final VoidCallback onAdminTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.infoSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.info,
              ),
              const SizedBox(width: 6),
              Text(
                'Demo access',
                style: texts.labelLarge?.copyWith(color: AppColors.info),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Work giver: 9811122233 or aarav@brightevents.in\n'
            'Worker: 9876543210 or ravi.kumar@example.com\n'
            'Password: jobmate123',
            style: texts.caption?.copyWith(color: const Color(0xFF075985)),
          ),
          TextButton(
            onPressed: onAdminTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 36),
              alignment: Alignment.centerLeft,
            ),
            child: const Text('Open admin console'),
          ),
        ],
      ),
    );
  }
}
