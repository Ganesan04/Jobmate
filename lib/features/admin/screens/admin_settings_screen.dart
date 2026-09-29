import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/info_row.dart';
import '../../../navigation/app_router.dart';
import '../../../state/admin_provider.dart';

/// Admin console settings: environment info and console sign out.
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    return AppScaffold(
      appBar: const AppTopBar(title: 'Console settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xs,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        children: <Widget>[
          AppCard(
            child: Column(
              children: <Widget>[
                const InfoRow(
                  label: 'Console',
                  value: 'Jobmate Admin 1.0.0',
                  icon: Icons.shield_rounded,
                  bold: true,
                ),
                InfoRow(
                  label: 'Server',
                  value: ApiConfig.baseUrl,
                  icon: Icons.dns_rounded,
                ),
                InfoRow(
                  label: 'Signed in as',
                  value: context.watch<AdminProvider>().email,
                  icon: Icons.alternate_email_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            color: AppColors.surfaceMuted,
            child: Text(
              'Moderation actions here change live accounts, jobs and disputes.',
              style: texts.caption,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SecondaryButton(
            label: 'Sign out of console',
            icon: Icons.logout_rounded,
            destructive: true,
            onPressed: () async {
              final bool confirmed = await showConfirmDialog(
                context,
                title: 'Sign out of the console?',
                message: 'You will need the admin credentials to sign back in.',
                confirmLabel: 'Sign out',
                destructive: true,
                icon: Icons.logout_rounded,
              );
              if (!confirmed || !context.mounted) return;
              context.read<AdminProvider>().signOut();
              AppRouter.pushReplacement(context, AppRoutes.adminLogin);
            },
          ),
        ],
      ),
    );
  }
}
