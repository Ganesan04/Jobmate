import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/enums.dart';
import '../../../models/job.dart';
import '../../../state/job_feed_provider.dart';

/// Admin jobs oversight: every listing with status filters.
class AdminJobsScreen extends StatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  State<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends State<AdminJobsScreen> {
  JobStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final List<Job> all = context.watch<JobFeedProvider>().jobs;
    final List<Job> jobs = _filter == null
        ? all
        : all.where((Job job) => job.status == _filter).toList();

    return AppScaffold(
      centerContent: false,
      appBar: AppTopBar(title: 'Jobs', subtitle: '${all.length} listing(s)'),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              children: <Widget>[
                SelectableChip(
                  label: 'All',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final JobStatus status in JobStatus.values) ...<Widget>[
                  const SizedBox(width: AppSpacing.xs),
                  SelectableChip(
                    label: status.label,
                    selected: _filter == status,
                    onTap: () => setState(
                      () => _filter = _filter == status ? null : status,
                    ),
                  ),
                ],
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: jobs.isEmpty
                ? const EmptyStateView(
                    title: 'No jobs here',
                    message: 'Nothing matches this status filter.',
                    icon: Icons.work_off_rounded,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.xs,
                      AppSpacing.screen,
                      AppSpacing.xl,
                    ),
                    itemCount: jobs.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (BuildContext context, int index) =>
                        _JobRow(job: jobs[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job});

  final Job job;

  static const List<Color> _palette = <Color>[
    Color(0xFF0EA5E9),
    Color(0xFF7C3AED),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  Color get _categoryColor => _palette[job.category.index % _palette.length];

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color.lerp(_categoryColor, Colors.white, 0.86),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(job.category.icon, size: 20, color: _categoryColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(job.title, style: texts.label),
                    const SizedBox(height: 2),
                    Text('${job.company} • ${job.area}', style: texts.caption),
                  ],
                ),
              ),
              StatusChip.job(job.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              StatusChip.neutral(
                AppFormat.paySuffix(job.totalPayout, job.payType.label),
                icon: Icons.payments_rounded,
                color: AppColors.success,
              ),
              StatusChip.neutral(
                AppFormat.dayMonth(job.date),
                icon: Icons.event_rounded,
              ),
              StatusChip.neutral(
                '${job.workersFilled}/${job.workersNeeded} filled',
                icon: Icons.groups_rounded,
              ),
              StatusChip.neutral(
                '${job.applicants} applicant(s)',
                icon: Icons.send_rounded,
              ),
              if (job.isUrgent)
                StatusChip.neutral(
                  'Urgent',
                  icon: Icons.bolt_rounded,
                  color: AppColors.error,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
