import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/job_card.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/application.dart';
import '../../../models/job.dart';
import '../../../navigation/app_router.dart';
import '../../../state/auth_provider.dart';
import '../../../state/chat_provider.dart';
import '../../../state/giver_provider.dart';
import '../../../state/notification_provider.dart';

/// Work giver dashboard: spend snapshot, hiring pipeline, jobs needing action
/// and a shortcut into the create-job flow.
class GiverHomeScreen extends StatefulWidget {
  const GiverHomeScreen({super.key});

  @override
  State<GiverHomeScreen> createState() => _GiverHomeScreenState();
}

class _GiverHomeScreenState extends State<GiverHomeScreen> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    final GiverProvider giver = context.read<GiverProvider>();
    final NotificationProvider notifications = context
        .read<NotificationProvider>();
    final ChatProvider chat = context.read<ChatProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      giver.load();
      notifications.load();
      chat.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final GiverProvider giver = context.watch<GiverProvider>();
    final NotificationProvider notifications = context
        .watch<NotificationProvider>();
    final ChatProvider chat = context.watch<ChatProvider>();
    final String name = auth.user?.firstName ?? 'there';

    return AppScaffold(
      centerContent: false,
      appBar: AppTopBar.tab(
        title: 'Hi, $name',
        subtitle: 'Manage your hiring',
        actions: <Widget>[
          AppIconButton(
            icon: Icons.notifications_none_rounded,
            badgeCount: notifications.unreadCount,
            tooltip: 'Notifications',
            onPressed: () => AppRouter.push(context, AppRoutes.notifications),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            badgeCount: chat.unreadTotal,
            tooltip: 'Messages',
            onPressed: () => AppRouter.push(context, AppRoutes.messages),
          ),
          const SizedBox(width: AppSpacing.xs),
          ProfileAvatar(
            name: auth.user?.name ?? 'You',
            size: AppSizes.avatarSm,
            onTap: () => AppRouter.push(context, AppRoutes.profile),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppRouter.push(context, AppRoutes.createJob),
        backgroundColor: context.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post a job'),
      ),
      body: RefreshIndicator(
        onRefresh: () => giver.load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xs,
            AppSpacing.screen,
            96,
          ),
          children: <Widget>[
            BalanceCard(
              title: 'Spent this month',
              amount: AppFormat.money(giver.spentThisMonth),
              subtitle: giver.toConfirm > 0
                  ? '${giver.toConfirm} worker(s) waiting for confirmation'
                  : 'No pending confirmations',
              icon: Icons.account_balance_wallet_rounded,
              gradient: const <Color>[
                AppColors.giverPrimary,
                Color(0xFFA78BFA),
              ],
              onTap: () => AppRouter.push(context, AppRoutes.myJobs),
            ),
            const SizedBox(height: AppSpacing.md),
            _Pipeline(giver: giver),
            const SizedBox(height: AppSpacing.lg),
            if (giver.toConfirm > 0) ...<Widget>[
              _ConfirmBanner(count: giver.toConfirm),
              const SizedBox(height: AppSpacing.md),
            ],
            SectionHeader(
              title: 'Your jobs',
              actionLabel: 'Manage',
              onAction: () => AppRouter.push(context, AppRoutes.myJobs),
            ),
            const SizedBox(height: AppSpacing.xs),
            _JobList(giver: giver),
          ],
        ),
      ),
    );
  }
}

class _Pipeline extends StatelessWidget {
  const _Pipeline({required this.giver});

  final GiverProvider giver;

  @override
  Widget build(BuildContext context) {
    final GiverStats stats = giver.stats;
    return StatGrid(
      columns: 2,
      stats: <StatCard>[
        StatCard(
          label: 'Active jobs',
          value: '${stats.activeJobs}',
          icon: Icons.bolt_rounded,
          compact: true,
          onTap: () => AppRouter.push(context, AppRoutes.myJobs),
        ),
        StatCard(
          label: 'Applicants',
          value: '${stats.applications}',
          icon: Icons.people_alt_rounded,
          color: const Color(0xFF0EA5E9),
          compact: true,
          onTap: () => AppRouter.push(context, AppRoutes.myJobs),
        ),
        StatCard(
          label: 'To confirm',
          value: '${stats.toConfirm}',
          icon: Icons.how_to_reg_rounded,
          color: AppColors.warning,
          compact: true,
          onTap: () => AppRouter.push(context, AppRoutes.myJobs),
        ),
        StatCard(
          label: 'Hired',
          value: '${stats.totalHired}',
          icon: Icons.handshake_rounded,
          color: AppColors.success,
          compact: true,
          onTap: () => AppRouter.push(context, AppRoutes.myJobs),
        ),
      ],
    );
  }
}

class _ConfirmBanner extends StatelessWidget {
  const _ConfirmBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.warningSurface,
      onTap: () => AppRouter.push(context, AppRoutes.myJobs),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.pending_actions_rounded,
              size: 21,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$count shortlisted worker${count == 1 ? '' : 's'} need your confirmation',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  const _JobList({required this.giver});

  final GiverProvider giver;

  @override
  Widget build(BuildContext context) {
    if (giver.isLoading && giver.myJobs.isEmpty) {
      return const JobCardSkeleton();
    }
    if (giver.hasError && giver.myJobs.isEmpty) {
      return ErrorStateView(
        message: giver.error ?? 'Could not load jobs',
        onRetry: giver.retry,
      );
    }
    if (giver.myJobs.isEmpty) {
      return EmptyStateView(
        title: 'No jobs posted yet',
        message: 'Post your first job to start receiving applications.',
        icon: Icons.post_add_rounded,
        actionLabel: 'Post a job',
        onAction: () => AppRouter.push(context, AppRoutes.createJob),
      );
    }
    final List<Job> jobs = giver.myJobs.take(3).toList();
    return Column(
      children: <Widget>[
        for (final Job job in jobs)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: JobCard(
              job: job,
              dense: true,
              status: job.status,
              onTap: () => AppRouter.push(
                context,
                AppRoutes.jobApplications,
                arguments: job.id,
              ),
              footer: _JobFooter(giver: giver, job: job),
            ),
          ),
      ],
    );
  }
}

class _JobFooter extends StatelessWidget {
  const _JobFooter({required this.giver, required this.job});

  final GiverProvider giver;
  final Job job;

  @override
  Widget build(BuildContext context) {
    final int applicants = giver.applicantsForJob(job.id).length;
    return Row(
      children: <Widget>[
        StatusChip.neutral(
          '$applicants applicant${applicants == 1 ? '' : 's'}',
          icon: Icons.people_alt_rounded,
        ),
        const SizedBox(width: AppSpacing.xs),
        StatusChip.neutral(
          '${job.workersFilled}/${job.workersNeeded} filled',
          icon: Icons.groups_rounded,
        ),
        const Spacer(),
        Text(
          AppFormat.money(job.pay),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: context.primary),
        ),
      ],
    );
  }
}
