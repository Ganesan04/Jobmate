import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/admin.dart';
import '../../../models/enums.dart';
import '../../../state/admin_provider.dart';
import '../../../state/job_feed_provider.dart';

/// Admin users table with search, role/verification filters and actions.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AdminProvider>().loadUsers(),
    );
  }

  Future<void> _refresh() =>
      context.read<AdminProvider>().loadUsers(showLoader: false);

  @override
  Widget build(BuildContext context) {
    final AdminProvider admin = context.watch<AdminProvider>();
    final List<AdminUser> users = admin.users;

    return AppScaffold(
      centerContent: false,
      appBar: const AppTopBar(title: 'Users'),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xs,
              AppSpacing.screen,
              AppSpacing.xs,
            ),
            child: AppTextField(
              hint: 'Search by name, phone or id',
              prefixIcon: Icons.search_rounded,
              onChanged: (String value) {
                admin.setUserQuery(value);
                _refresh();
              },
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              children: <Widget>[
                SelectableChip(
                  label: 'All roles',
                  selected: admin.userRole == null,
                  onTap: () {
                    admin.setUserRole(null);
                    _refresh();
                  },
                ),
                for (final UserRole role in UserRole.values) ...<Widget>[
                  const SizedBox(width: AppSpacing.xs),
                  SelectableChip(
                    label: role.label,
                    selected: admin.userRole == role,
                    onTap: () {
                      admin.setUserRole(admin.userRole == role ? null : role);
                      _refresh();
                    },
                  ),
                ],
                const SizedBox(width: AppSpacing.xs),
                SelectableChip(
                  label: 'Verified',
                  selected:
                      admin.userVerification == VerificationStatus.verified,
                  onTap: () {
                    admin.setUserVerification(
                      admin.userVerification == VerificationStatus.verified
                          ? null
                          : VerificationStatus.verified,
                    );
                    _refresh();
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: switch (admin.usersState) {
              LoadState.loading ||
              LoadState.idle => const SkeletonList(count: 6),
              LoadState.error => ErrorStateView(onRetry: admin.loadUsers),
              LoadState.ready =>
                users.isEmpty
                    ? const EmptyStateView(
                        title: 'No users found',
                        message: 'Try a different search or filter.',
                        icon: Icons.people_outline_rounded,
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screen,
                            AppSpacing.xs,
                            AppSpacing.screen,
                            AppSpacing.xl,
                          ),
                          itemCount: users.length,
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (BuildContext context, int index) =>
                              _UserCard(user: users[index]),
                        ),
                      ),
            },
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final AdminUser user;

  Future<void> _toggleActive(BuildContext context) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: user.isActive
          ? 'Deactivate ${user.name}?'
          : 'Reactivate ${user.name}?',
      message: user.isActive
          ? 'They will not be able to apply for jobs or post new jobs.'
          : 'They will be able to use Jobmate again.',
      confirmLabel: user.isActive ? 'Deactivate' : 'Reactivate',
      destructive: user.isActive,
      icon: Icons.person_off_rounded,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<AdminProvider>().setUserActive(user.id, !user.isActive);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ProfileAvatar(name: user.name, size: 44),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(user.name, style: texts.label),
                    const SizedBox(height: 2),
                    Text(
                      '+91 ${user.phone}${user.area.isEmpty ? '' : ' • ${user.area}'}',
                      style: texts.caption,
                    ),
                  ],
                ),
              ),
              StatusChip.neutral(
                user.role.label,
                color: user.role == UserRole.worker
                    ? AppColors.workerPrimary
                    : AppColors.giverPrimary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              StatusChip.verification(user.verification),
              StatusChip.neutral(
                user.isActive ? 'Active' : 'Inactive',
                icon: user.isActive
                    ? Icons.check_circle_rounded
                    : Icons.pause_circle_rounded,
                color: user.isActive ? AppColors.success : AppColors.error,
              ),
              StatusChip.neutral('${user.jobsCount} job(s)'),
              StatusChip.neutral(
                'Joined ${AppFormat.dayMonth(user.joinedOn)}',
                icon: Icons.calendar_today_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              TextButton.icon(
                onPressed: () => _showDetail(context),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Details'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _toggleActive(context),
                icon: Icon(
                  user.isActive
                      ? Icons.block_rounded
                      : Icons.check_circle_rounded,
                  size: 18,
                  color: user.isActive ? AppColors.error : AppColors.success,
                ),
                label: Text(
                  user.isActive ? 'Deactivate' : 'Reactivate',
                  style: texts.caption?.copyWith(
                    color: user.isActive ? AppColors.error : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showAppSheet<void>(
      context: context,
      title: user.name,
      subtitle: user.role.label,
      child: Builder(
        builder: (BuildContext sheetContext) {
          final TextTheme texts = Theme.of(sheetContext).textTheme;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              InfoRow(
                label: 'User id',
                value: user.id,
                icon: Icons.tag_rounded,
              ),
              InfoRow(
                label: 'Phone',
                value: '+91 ${user.phone}',
                icon: Icons.call_rounded,
              ),
              if (user.area.isNotEmpty)
                InfoRow(
                  label: 'Area',
                  value: user.area,
                  icon: Icons.place_rounded,
                ),
              InfoRow(
                label: 'Jobs',
                value: '${user.jobsCount}',
                icon: Icons.work_rounded,
              ),
              InfoRow(
                label: 'Verification',
                value: user.verification.label,
                icon: Icons.verified_user_rounded,
              ),
              InfoRow(
                label: 'Joined',
                value: AppFormat.dayMonthYear(user.joinedOn),
                icon: Icons.event_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Suspends and verifications are recorded in the moderation log in a real build.',
                style: texts.caption,
              ),
            ],
          );
        },
      ),
    );
  }
}
