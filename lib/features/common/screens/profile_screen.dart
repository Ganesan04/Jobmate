import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/enums.dart';
import '../../../models/user.dart';
import '../../../navigation/app_router.dart';
import '../../../state/auth_provider.dart';
import '../../../state/giver_provider.dart';
import '../../../state/worker_provider.dart';

/// Profile tab: identity header, role-aware stats and the settings menu.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final AuthProvider auth = context.watch<AuthProvider>();
    final UserProfile? user = auth.user;
    if (user == null) {
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final bool isWorker = user.role == UserRole.worker;

    return AppScaffold(
      centerContent: false,
      appBar: AppTopBar.tab(
        title: 'Profile',
        actions: <Widget>[
          AppIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            onPressed: () => AppRouter.push(context, AppRoutes.settings),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xs,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        children: <Widget>[
          AppCard(
            elevated: true,
            child: Column(
              children: <Widget>[
                ProfileAvatar(
                  name: user.name,
                  size: 84,
                  showOnlineDot: true,
                  isOnline: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(user.name, style: texts.headline),
                const SizedBox(height: 2),
                Text(
                  '${user.role.label} • ${user.area}',
                  style: texts.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    StatusChip.neutral(
                      user.rating > 0
                          ? '${user.rating.toStringAsFixed(1)} rating'
                          : 'New on Jobmate',
                      icon: Icons.star_rounded,
                      color: user.rating > 0
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                    StatusChip.neutral(
                      '${user.jobsCompleted} job(s) done',
                      icon: Icons.task_alt_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SecondaryButton(
                        label: 'Edit profile',
                        icon: Icons.edit_rounded,
                        onPressed: () =>
                            AppRouter.push(context, AppRoutes.editProfile),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: PrimaryButton(
                        label: isWorker ? 'Find work' : 'Post a job',
                        icon: isWorker
                            ? Icons.search_rounded
                            : Icons.add_rounded,
                        onPressed: () => AppRouter.push(
                          context,
                          isWorker ? AppRoutes.searchJobs : AppRoutes.createJob,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (user.skills.isNotEmpty) ...<Widget>[
            const SectionHeader(title: 'Skills'),
            const SizedBox(height: AppSpacing.xs),
            AppCard(
              child: ChipWrap(
                children: user.skills
                    .map((String skill) => StatusChip.neutral(skill))
                    .toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _StatsRow(user: user),
          const SizedBox(height: AppSpacing.md),
          MenuGroup(
            children: <Widget>[
              MenuTile(
                title: 'Verification centre',
                subtitle: 'ID, phone and skills verification',
                icon: Icons.verified_user_rounded,
                onTap: () =>
                    AppRouter.push(context, AppRoutes.verificationCentre),
              ),
              MenuTile(
                title: isWorker ? 'Work history' : 'Hired workers',
                subtitle: isWorker
                    ? '${context.watch<WorkerProvider>().history.length} completed job(s)'
                    : '${context.watch<GiverProvider>().totalHired} worker(s) hired',
                icon: Icons.history_rounded,
                onTap: () => AppRouter.push(context, AppRoutes.workHistory),
              ),
              MenuTile(
                title: 'Switch role',
                subtitle: isWorker
                    ? 'Hire workers instead'
                    : 'Find work instead',
                icon: Icons.swap_horiz_rounded,
                onTap: () => _switchRole(context, auth, user.role),
              ),
              MenuTile(
                title: 'Help & support',
                subtitle: 'FAQs, report a problem, contact us',
                icon: Icons.help_outline_rounded,
                onTap: () => AppRouter.push(context, AppRoutes.help),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _switchRole(
    BuildContext context,
    AuthProvider auth,
    UserRole current,
  ) async {
    final UserRole next = current == UserRole.worker
        ? UserRole.workGiver
        : UserRole.worker;
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Switch to ${next.label}?',
      message:
          'Your account stays the same. You will see the ${next.label.toLowerCase()} '
          'experience and theme after switching.',
      confirmLabel: 'Switch role',
      icon: Icons.swap_horiz_rounded,
    );
    if (!confirmed || !context.mounted) return;
    final NavigatorState navigator = Navigator.of(context);
    final bool ok = await auth.switchRole(next);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Could not switch role')),
      );
      return;
    }
    AppRouter.popToRoot(context);
    // An account that only ever hired has no skills yet, and workers are
    // matched to jobs by skill, so the profile form is offered once.
    if (next == UserRole.worker && (auth.user?.skills.isEmpty ?? false)) {
      navigator.pushNamed(AppRoutes.editProfile);
    }
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    if (user.role == UserRole.worker) {
      final WorkerProvider worker = context.watch<WorkerProvider>();
      return StatGrid(
        columns: 2,
        stats: <StatCard>[
          StatCard(
            label: 'Applications',
            value: '${worker.applications.length}',
            icon: Icons.send_rounded,
            compact: true,
          ),
          StatCard(
            label: 'Completed',
            value: '${worker.history.length}',
            icon: Icons.task_alt_rounded,
            color: AppColors.success,
            compact: true,
          ),
        ],
      );
    }
    final GiverProvider giver = context.watch<GiverProvider>();
    return StatGrid(
      columns: 2,
      stats: <StatCard>[
        StatCard(
          label: 'Active jobs',
          value: '${giver.activeJobs.length}',
          icon: Icons.bolt_rounded,
          compact: true,
        ),
        StatCard(
          label: 'Workers hired',
          value: '${giver.totalHired}',
          icon: Icons.handshake_rounded,
          color: AppColors.success,
          compact: true,
        ),
      ],
    );
  }
}
