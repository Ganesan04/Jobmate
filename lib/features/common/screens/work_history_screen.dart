import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/enums.dart';
import '../../../models/application.dart';
import '../../../models/job.dart';
import '../../../state/auth_provider.dart';
import '../../../state/giver_provider.dart';
import '../../../state/worker_provider.dart';

/// Work history: workers see completed jobs, givers see who they hired.
class WorkHistoryScreen extends StatefulWidget {
  const WorkHistoryScreen({super.key});

  @override
  State<WorkHistoryScreen> createState() => _WorkHistoryScreenState();
}

class _WorkHistoryScreenState extends State<WorkHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final UserRole role = context.watch<AuthProvider>().role;
    return role == UserRole.workGiver
        ? const _GiverHistory()
        : const _WorkerHistory();
  }
}

class _WorkerHistory extends StatelessWidget {
  const _WorkerHistory();

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final List<WorkHistoryEntry> entries = context
        .watch<WorkerProvider>()
        .history;
    final int total = entries.fold<int>(
      0,
      (int sum, WorkHistoryEntry e) => sum + e.earnings,
    );
    final double hours = entries.fold<double>(
      0,
      (double sum, WorkHistoryEntry e) => sum + e.durationHours,
    );

    return AppScaffold(
      appBar: const AppTopBar(title: 'Work history'),
      body: entries.isEmpty
          ? const EmptyStateView(
              title: 'No completed jobs yet',
              message: 'Finish your first job and it will show up here.',
              icon: Icons.history_rounded,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.xs,
                AppSpacing.screen,
                AppSpacing.xl,
              ),
              children: <Widget>[
                StatGrid(
                  columns: 3,
                  stats: <StatCard>[
                    StatCard(
                      label: 'Jobs',
                      value: '${entries.length}',
                      icon: Icons.task_alt_rounded,
                      compact: true,
                    ),
                    StatCard(
                      label: 'Hours',
                      value: hours.toStringAsFixed(0),
                      icon: Icons.schedule_rounded,
                      compact: true,
                    ),
                    StatCard(
                      label: 'Earned',
                      value: AppFormat.money(total),
                      icon: Icons.payments_rounded,
                      color: AppColors.success,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Completed jobs'),
                const SizedBox(height: AppSpacing.xs),
                for (final WorkHistoryEntry entry in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(entry.jobTitle, style: texts.label),
                                    const SizedBox(height: 2),
                                    Text(entry.company, style: texts.caption),
                                  ],
                                ),
                              ),
                              Text(
                                AppFormat.money(entry.earnings),
                                style: texts.label?.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: <Widget>[
                              StatusChip.neutral(
                                AppFormat.dayMonthYear(entry.date),
                                icon: Icons.event_rounded,
                              ),
                              StatusChip.neutral(
                                '${entry.durationHours.toStringAsFixed(1)} hrs',
                                icon: Icons.schedule_rounded,
                              ),
                              StatusChip.payment(entry.paymentStatus),
                              if (entry.rating != null)
                                StatusChip.neutral(
                                  '${entry.rating!.toStringAsFixed(1)} rating',
                                  icon: Icons.star_rounded,
                                  color: AppColors.warning,
                                ),
                            ],
                          ),
                          if (!entry.ratedByGiver) ...<Widget>[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Waiting for the work giver to rate you',
                              style: texts.caption,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _GiverHistory extends StatelessWidget {
  const _GiverHistory();

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final GiverProvider giver = context.watch<GiverProvider>();
    final List<Job> jobs = giver.myJobs
        .where((Job job) => job.status == JobStatus.completed)
        .toList();
    final List<Job> live = giver.inProgressJobs;

    return AppScaffold(
      appBar: const AppTopBar(title: 'Hired workers'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xs,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        children: <Widget>[
          StatGrid(
            columns: 3,
            stats: <StatCard>[
              StatCard(
                label: 'In progress',
                value: '${live.length}',
                icon: Icons.engineering_rounded,
                compact: true,
              ),
              StatCard(
                label: 'Completed',
                value: '${jobs.length}',
                icon: Icons.task_alt_rounded,
                compact: true,
              ),
              StatCard(
                label: 'Hired',
                value: '${giver.totalHired}',
                icon: Icons.handshake_rounded,
                color: AppColors.giverPrimary,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Currently hiring'),
          const SizedBox(height: AppSpacing.xs),
          if (live.isEmpty)
            const EmptyStateView(
              title: 'Nobody hired right now',
              message: 'Shortlist a worker from a job to see them here.',
              icon: Icons.handshake_rounded,
              compact: true,
            )
          else
            for (final Job job in live)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(job.title, style: texts.label),
                            const SizedBox(height: 2),
                            Text(
                              '${job.applicants} applicant(s) • '
                              '${AppFormat.dayMonthYear(job.date)}',
                              style: texts.caption,
                            ),
                          ],
                        ),
                      ),
                      StatusChip.job(job.status),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Completed jobs'),
          const SizedBox(height: AppSpacing.xs),
          if (jobs.isEmpty)
            const EmptyStateView(
              title: 'No completed jobs',
              message: 'Finished jobs and the workers you hired appear here.',
              icon: Icons.history_rounded,
              compact: true,
            )
          else
            for (final Job job in jobs)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(job.title, style: texts.label),
                            const SizedBox(height: 2),
                            Text(
                              '${job.area} • ${AppFormat.dayMonthYear(job.date)}',
                              style: texts.caption,
                            ),
                          ],
                        ),
                      ),
                      StatusChip.job(job.status),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
