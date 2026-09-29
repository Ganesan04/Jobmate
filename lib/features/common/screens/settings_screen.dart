import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/user.dart';
import '../../../navigation/app_router.dart';
import '../../../state/auth_provider.dart';

/// Settings: account, notifications, privacy, language and sign out.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _jobAlerts = true;
  bool _paymentAlerts = true;
  bool _chatAlerts = true;
  bool _showDistance = true;

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final UserProfile? user = auth.user;

    return AppScaffold(
      appBar: const AppTopBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xs,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        children: <Widget>[
          if (user != null)
            AppCard(
              child: Column(
                children: <Widget>[
                  InfoRow(
                    label: 'Name',
                    value: user.name,
                    icon: Icons.person_outline_rounded,
                    bold: true,
                  ),
                  InfoRow(
                    label: 'Mobile',
                    value: '+91 ${user.phone}',
                    icon: Icons.phone_iphone_rounded,
                  ),
                  if (user.email.isNotEmpty)
                    InfoRow(
                      label: 'Email',
                      value: user.email,
                      icon: Icons.alternate_email_rounded,
                    ),
                  InfoRow(
                    label: 'Role',
                    value: user.role.label,
                    icon: Icons.badge_outlined,
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          MenuGroup(
            title: 'Account',
            children: <Widget>[
              MenuTile(
                title: 'Edit profile',
                icon: Icons.edit_rounded,
                onTap: () => AppRouter.push(context, AppRoutes.editProfile),
              ),
              MenuTile(
                title: 'Verification centre',
                icon: Icons.verified_user_rounded,
                onTap: () =>
                    AppRouter.push(context, AppRoutes.verificationCentre),
              ),
              MenuTile(
                title: 'Change mobile number',
                icon: Icons.swap_horiz_rounded,
                onTap: () => AppRouter.push(context, AppRoutes.forgotPassword),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          MenuGroup(
            title: 'Notifications',
            children: <Widget>[
              SwitchListTile.adaptive(
                value: _jobAlerts,
                onChanged: (bool value) => setState(() => _jobAlerts = value),
                title: const Text('Job alerts'),
                subtitle: const Text('New jobs matching your skills'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
              ),
              SwitchListTile.adaptive(
                value: _paymentAlerts,
                onChanged: (bool value) =>
                    setState(() => _paymentAlerts = value),
                title: const Text('Payment alerts'),
                subtitle: const Text('Payment released or disputed'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
              ),
              SwitchListTile.adaptive(
                value: _chatAlerts,
                onChanged: (bool value) => setState(() => _chatAlerts = value),
                title: const Text('Message alerts'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          MenuGroup(
            title: 'Privacy',
            children: <Widget>[
              SwitchListTile.adaptive(
                value: _showDistance,
                onChanged: (bool value) =>
                    setState(() => _showDistance = value),
                title: const Text('Show distance to jobs'),
                subtitle: const Text(
                  'Hide your exact distance from work givers',
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
              ),
              MenuTile(
                title: 'Replay onboarding',
                subtitle: 'See the intro screens again',
                icon: Icons.slideshow_rounded,
                onTap: () async {
                  final bool confirmed = await showConfirmDialog(
                    context,
                    title: 'Replay onboarding?',
                    message: 'You will be taken back to the intro screens.',
                    confirmLabel: 'Replay',
                  );
                  if (!confirmed || !context.mounted) return;
                  AppRouter.popToRoot(context);
                  auth.replayOnboarding();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          MenuGroup(
            title: 'Support',
            children: <Widget>[
              MenuTile(
                title: 'Help & FAQs',
                icon: Icons.help_outline_rounded,
                onTap: () => AppRouter.push(context, AppRoutes.help),
              ),
              MenuTile(
                title: 'Report a problem',
                icon: Icons.flag_outlined,
                onTap: () => AppRouter.push(context, AppRoutes.reportProblem),
              ),
              MenuTile(
                title: 'Contact support',
                icon: Icons.support_agent_rounded,
                onTap: () => AppRouter.push(context, AppRoutes.contactSupport),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'About'),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            color: AppColors.surfaceMuted,
            child: Column(
              children: <Widget>[
                InfoRow(
                  label: 'App',
                  value: 'Jobmate 1.0.0',
                  icon: Icons.info_outline_rounded,
                ),
                InfoRow(
                  label: 'Server',
                  value: ApiConfig.baseUrl,
                  icon: Icons.dns_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SecondaryButton(
            label: 'Sign out',
            icon: Icons.logout_rounded,
            destructive: true,
            onPressed: () async {
              final bool confirmed = await showConfirmDialog(
                context,
                title: 'Sign out?',
                message:
                    'You will need to sign in again with your mobile number.',
                confirmLabel: 'Sign out',
                destructive: true,
                icon: Icons.logout_rounded,
              );
              if (!confirmed || !context.mounted) return;
              await auth.signOut();
              if (context.mounted) AppRouter.popToRoot(context);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: StatusChip.neutral('Jobmate', icon: Icons.verified_rounded),
          ),
        ],
      ),
    );
  }
}
