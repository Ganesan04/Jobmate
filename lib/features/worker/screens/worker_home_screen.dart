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
import '../../../state/job_feed_provider.dart';
import '../../../state/notification_provider.dart';
import '../../../state/worker_provider.dart';

/// Worker dashboard: greeting, earnings snapshot, active work, application
/// summary and a nearby-jobs feed.
class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    final JobFeedProvider feed = context.read<JobFeedProvider>();
    final WorkerProvider worker = context.read<WorkerProvider>();
    final NotificationProvider notifications = context
        .read<NotificationProvider>();
    final ChatProvider chat = context.read<ChatProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      feed.load();
      feed.loadSaved();
      worker.load();
      notifications.load();
      chat.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final JobFeedProvider feed = context.watch<JobFeedProvider>();
    final WorkerProvider worker = context.watch<WorkerProvider>();
    final NotificationProvider notifications = context
        .watch<NotificationProvider>();
    final ChatProvider chat = context.watch<ChatProvider>();
    final String name = auth.user?.firstName ?? 'there';

    return AppScaffold(
      centerContent: false,
      appBar: AppTopBar.tab(
        title: 'Hi, $name',
        subtitle: _greeting(),
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
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait<void>(<Future<void>>[
            feed.load(),
            worker.load(),
            notifications.load(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xs,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          children: <Widget>[
            _EarningsSnapshot(worker: worker),
            const SizedBox(height: AppSpacing.md),
            _ActiveWork(worker: worker),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(
              title: 'Your activity',
              actionLabel: 'View all',
              onAction: () => AppRouter.push(context, AppRoutes.applications),
            ),
            const SizedBox(height: AppSpacing.xs),
            _ActivityRow(worker: worker),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(
              title: 'Jobs near you',
              actionLabel: 'See all',
              onAction: () => AppRouter.push(context, AppRoutes.searchJobs),
            ),
            const SizedBox(height: AppSpacing.xs),
            _NearbyJobs(feed: feed),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, ready to work?';
    if (hour < 17) return 'Good afternoon, ready to work?';
    return 'Good evening, ready to work?';
  }
}

class _EarningsSnapshot extends StatelessWidget {
  const _EarningsSnapshot({required this.worker});

  final WorkerProvider worker;

  @override
  Widget build(BuildContext context) {
    return BalanceCard(
      title: 'Total earnings',
      amount: AppFormat.money(worker.totalEarned),
      subtitle: worker.pendingAmount > 0
          ? '${AppFormat.money(worker.pendingAmount)} pending release'
          : 'All payments are up to date',
      icon: Icons.account_balance_wallet_rounded,
      onTap: () => AppRouter.push(context, AppRoutes.earnings),
    );
  }
}

/// The worker's next confirmed job, or a prompt to apply when nothing is booked.
class _ActiveWork extends StatelessWidget {
  const _ActiveWork({required this.worker});

  final WorkerProvider worker;

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final List<WorkerAssignment> active = worker.activeAssignments;
    if (active.isEmpty) {
      return AppCard(
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.primaryTint,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.event_available_rounded,
                size: 22,
                color: context.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('No upcoming work', style: texts.label),
                  const SizedBox(height: 2),
                  Text('Apply to jobs to get booked.', style: texts.caption),
                ],
              ),
            ),
            TextButton(
              onPressed: () => AppRouter.push(context, AppRoutes.searchJobs),
              child: const Text('Find work'),
            ),
          ],
        ),
      );
    }

    final WorkerAssignment assignment = active.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(title: 'Next job'),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          onTap: () => AppRouter.push(
            context,
            AppRoutes.acceptedJob,
            arguments: assignment.jobId,
          ),
          child: Row(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Text(
                    AppFormat.dayMonth(assignment.confirmedAt),
                    style: texts.labelLarge?.copyWith(color: context.primary),
                  ),
                  Text(
                    assignment.confirmedAt.hour.toString().padLeft(2, '0'),
                    style: texts.caption,
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Container(width: 1, height: 44, color: AppColors.border),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Confirmed job', style: texts.label),
                    const SizedBox(height: 2),
                    Text(
                      assignment.isCheckedIn
                          ? 'Checked in • ${AppFormat.money(assignment.agreedPay)}'
                          : '${AppFormat.money(assignment.agreedPay)} • tap for details',
                      style: texts.caption,
                    ),
                  ],
                ),
              ),
              StatusChip.neutral(
                assignment.isCheckedIn ? 'On site' : 'Upcoming',
                icon: assignment.isCheckedIn
                    ? Icons.location_on_rounded
                    : Icons.schedule_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.worker});

  final WorkerProvider worker;

  @override
  Widget build(BuildContext context) {
    final WorkerStats stats = worker.stats;
    return StatGrid(
      columns: 2,
      stats: <StatCard>[
        StatCard(
          label: 'Applied',
          value: '${stats.applied}',
          icon: Icons.send_rounded,
          compact: true,
          onTap: () => AppRouter.push(context, AppRoutes.applications),
        ),
        StatCard(
          label: 'Active',
          value: '${stats.active}',
          icon: Icons.play_circle_outline_rounded,
          color: const Color(0xFF0EA5E9),
          compact: true,
          onTap: () => AppRouter.push(context, AppRoutes.applications),
        ),
        StatCard(
          label: 'Completed',
          value: '${stats.completed}',
          icon: Icons.task_alt_rounded,
          color: const Color(0xFF10B981),
          compact: true,
          onTap: () => AppRouter.push(context, AppRoutes.workHistory),
        ),
        StatCard(
          label: 'This month',
          value: AppFormat.moneyCompact(stats.earnings),
          icon: Icons.payments_rounded,
          compact: true,
          onTap: () => AppRouter.push(context, AppRoutes.earnings),
        ),
      ],
    );
  }
}

class _NearbyJobs extends StatelessWidget {
  const _NearbyJobs({required this.feed});

  final JobFeedProvider feed;

  @override
  Widget build(BuildContext context) {
    if (feed.isLoading && feed.jobs.isEmpty) {
      return const JobCardSkeleton();
    }
    if (feed.hasError && feed.jobs.isEmpty) {
      return ErrorStateView(
        message: feed.error ?? 'Could not load jobs',
        onRetry: feed.retry,
      );
    }
    if (feed.jobs.isEmpty) {
      return EmptyStateView(
        title: 'No open jobs right now',
        message: 'Check back soon or widen your search filters.',
        icon: Icons.work_off_rounded,
        actionLabel: 'Search jobs',
        onAction: () => AppRouter.push(context, AppRoutes.searchJobs),
      );
    }
    final List<Job> jobs = feed.jobs.take(3).toList();
    return Column(
      children: <Widget>[
        for (final Job job in jobs)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: JobCard(
              job: job,
              isSaved: feed.isSaved(job.id),
              onTap: () => AppRouter.push(
                context,
                AppRoutes.jobDetails,
                arguments: job.id,
              ),
              onSave: () => feed.toggleSaved(job),
            ),
          ),
      ],
    );
  }
}
