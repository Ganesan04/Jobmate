import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/enums.dart';
import '../../../models/job.dart';
import '../../../navigation/app_router.dart';
import '../../../state/job_feed_provider.dart';
import '../../../state/worker_provider.dart';

/// Full job description with the pay header, requirement grid, safety notes and
/// a sticky apply / already-applied bar.
class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({super.key, required this.jobId});

  final String jobId;

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  Job? _job;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final Job job = await context.read<JobFeedProvider>().jobById(
        widget.jobId,
      );
      if (mounted) setState(() => _job = job);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Job? job = _job;
    if (_loading && job == null) {
      return const AppScaffold(
        appBar: AppTopBar(title: 'Job details'),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (job == null) {
      return AppScaffold(
        appBar: const AppTopBar(title: 'Job details'),
        body: EmptyStateView(
          title: 'Job unavailable',
          message: 'This job may have been filled or removed.',
          icon: Icons.search_off_rounded,
          actionLabel: 'Back to jobs',
          onAction: () =>
              AppRouter.pushReplacement(context, AppRoutes.searchJobs),
        ),
      );
    }

    final JobFeedProvider feed = context.watch<JobFeedProvider>();
    final WorkerProvider worker = context.watch<WorkerProvider>();
    final TextTheme texts = Theme.of(context).textTheme;
    final bool isSaved = feed.isSaved(job.id);
    final bool hasApplied = worker.applications.any(
      (dynamic application) => application.jobId == job.id,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppScaffold(
        centerContent: false,
        appBar: AppTopBar(
          title: 'Job details',
          actions: <Widget>[
            AppIconButton(
              icon: isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              tooltip: isSaved ? 'Remove from saved' : 'Save job',
              onPressed: () => feed.toggleSaved(job),
            ),
            const SizedBox(width: AppSpacing.xs),
            AppIconButton(
              icon: Icons.ios_share_rounded,
              tooltip: 'Share',
              onPressed: () => _share(context, job),
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
            _PayHeader(job: job),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                if (job.isUrgent)
                  StatusChip.neutral('Urgent', icon: Icons.bolt_rounded),
                StatusChip.job(job.status),
                StatusChip.neutral(job.category.label, icon: job.category.icon),
                if (job.contactPerson.isNotEmpty)
                  StatusChip.neutral(
                    'Verified giver',
                    icon: Icons.verified_rounded,
                    color: AppColors.success,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionHeader(
                    title: 'Job requirements',
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InfoRow(
                    label: 'Category',
                    value: job.category.label,
                    icon: job.category.icon,
                  ),
                  InfoRow(
                    label: 'Experience',
                    value: job.experienceLabel,
                    icon: Icons.workspace_premium_outlined,
                  ),
                  InfoRow(
                    label: 'Workplace',
                    value: job.workplaceType.label,
                    icon: Icons.domain_rounded,
                  ),
                  InfoRow(
                    label: 'Job type',
                    value: job.jobType.label,
                    icon: Icons.repeat_rounded,
                  ),
                  if (job.isRecurring)
                    InfoRow(
                      label: 'Days',
                      value: job.weekdays
                          .map((WorkDay d) => d.shortLabel)
                          .join(', '),
                      icon: Icons.calendar_month_rounded,
                    ),
                  if (job.vehicleRequired)
                    const InfoRow(
                      label: 'Vehicle',
                      value: 'Two-wheeler required',
                      icon: Icons.two_wheeler_rounded,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionHeader(
                    title: 'About this job',
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(job.description, style: texts.body),
                  if (job.skills.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    const OverlineLabel('Skills required'),
                    const SizedBox(height: AppSpacing.xs),
                    ChipWrap(
                      children: job.skills
                          .map((String skill) => StatusChip.neutral(skill))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionHeader(
                    title: 'Location & contact',
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InfoRow(
                    label: 'Area',
                    value: job.area,
                    icon: Icons.location_city_rounded,
                  ),
                  InfoRow(
                    label: 'Distance',
                    value: AppFormat.distance(job.distanceKm),
                    icon: Icons.near_me_rounded,
                  ),
                  if (job.locationVisible)
                    InfoRow(
                      label: 'Address',
                      value: job.address,
                      icon: Icons.map_outlined,
                    ),
                  if (job.contactPerson.isNotEmpty)
                    InfoRow(
                      label: 'Contact person',
                      value: job.contactPerson,
                      icon: Icons.person_outline_rounded,
                    ),
                  InfoRow(
                    label: 'Report time',
                    value: job.reportTime,
                    icon: Icons.schedule_rounded,
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              color: AppColors.infoSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionHeader(
                    title: 'Safety & conduct',
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InfoRow(
                    label: 'Dress code',
                    value: job.dressCode,
                    icon: Icons.checkroom_rounded,
                  ),
                  InfoRow(
                    label: 'Physical needs',
                    value: job.physicalRequirement,
                    icon: Icons.accessibility_new_rounded,
                  ),
                  InfoRow(
                    label: 'Safety note',
                    value: job.safetyInfo,
                    icon: Icons.health_and_safety_rounded,
                  ),
                  if (job.emergencyContact.isNotEmpty)
                    InfoRow(
                      label: 'Emergency contact',
                      value: job.emergencyContact,
                      icon: Icons.emergency_rounded,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: 'Report a problem',
              icon: Icons.flag_outlined,
              onPressed: () => AppRouter.push(context, AppRoutes.reportProblem),
            ),
          ],
        ),
      ),
      bottomNavigationBar: StickyActionBar(
        child: hasApplied
            ? SecondaryButton(
                label: 'You have applied',
                icon: Icons.check_circle_rounded,
                onPressed: () =>
                    AppRouter.push(context, AppRoutes.applications),
              )
            : PrimaryButton(
                label: 'Apply for this job',
                icon: Icons.send_rounded,
                onPressed: () async {
                  await AppRouter.push(
                    context,
                    AppRoutes.apply,
                    arguments: job.id,
                  );
                  if (mounted) setState(() {});
                },
              ),
      ),
    );
  }

  void _share(BuildContext context, Job job) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share link copied for "${job.title}"'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _PayHeader extends StatelessWidget {
  const _PayHeader({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    return AppCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(job.title, style: texts.headline),
          const SizedBox(height: 2),
          Text(job.company, style: texts.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                AppFormat.money(job.totalPayout),
                style: texts.display?.copyWith(color: context.primary),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${job.payType.label} / worker',
                  style: texts.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              StatusChip.neutral(
                AppFormat.weekdayDate(job.date),
                icon: Icons.calendar_today_rounded,
              ),
              StatusChip.neutral(job.timeRange, icon: Icons.schedule_rounded),
              StatusChip.neutral(
                '${job.remainingWorkers} slot(s) left',
                icon: Icons.groups_rounded,
                color: job.remainingWorkers > 0
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ],
          ),
          if (job.travelAllowance > 0 || job.foodAllowance > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Includes ${AppFormat.money(job.travelAllowance)} travel + '
              '${AppFormat.money(job.foodAllowance)} food allowance',
              style: texts.caption,
            ),
          ],
        ],
      ),
    );
  }
}
