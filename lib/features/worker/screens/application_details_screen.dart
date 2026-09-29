import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/application.dart';
import '../../../models/enums.dart';
import '../../../models/job.dart';
import '../../../navigation/app_router.dart';
import '../../../state/job_feed_provider.dart';
import '../../../state/worker_provider.dart';

/// Timeline-style view of one application: status steps, message, job snapshot.
class ApplicationDetailsScreen extends StatefulWidget {
  const ApplicationDetailsScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  State<ApplicationDetailsScreen> createState() =>
      _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final WorkerProvider worker = context.watch<WorkerProvider>();
    final JobFeedProvider feed = context.watch<JobFeedProvider>();

    final JobApplication? application = worker.applications
        .where((JobApplication a) => a.id == widget.applicationId)
        .firstOrNull;
    if (application == null) {
      return AppScaffold(
        appBar: const AppTopBar(title: 'Application'),
        body: EmptyStateView(
          title: 'Application not found',
          message: 'It may have been withdrawn or removed.',
          icon: Icons.search_off_rounded,
          actionLabel: 'Back to applications',
          onAction: () =>
              AppRouter.pushReplacement(context, AppRoutes.applications),
        ),
      );
    }

    return FutureBuilder<Job>(
      future: feed.jobById(application.jobId),
      builder: (BuildContext context, AsyncSnapshot<Job> snapshot) {
        final Job? job = snapshot.data;
        return AppScaffold(
          appBar: const AppTopBar(title: 'Application'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            job?.title ?? 'Job',
                            style: texts.titleMedium,
                          ),
                        ),
                        StatusChip.application(application.status),
                      ],
                    ),
                    if (job != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(job.company, style: texts.bodyMedium),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: <Widget>[
                          Text(
                            AppFormat.money(job.totalPayout),
                            style: texts.titleLarge?.copyWith(
                              color: context.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(job.payType.label, style: texts.caption),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: 'View job',
                      icon: Icons.open_in_new_rounded,
                      onPressed: job == null
                          ? null
                          : () => AppRouter.push(
                              context,
                              AppRoutes.jobDetails,
                              arguments: job.id,
                            ),
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
                      title: 'Progress',
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _Timeline(application: application),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionHeader(
                      title: 'Your application',
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    InfoRow(
                      label: 'Applied on',
                      value: AppFormat.fullDate(application.appliedDate),
                      icon: Icons.event_rounded,
                    ),
                    InfoRow(
                      label: 'Availability',
                      value: application.availableFrom,
                      icon: Icons.schedule_rounded,
                    ),
                    if (application.expectedPay != null)
                      InfoRow(
                        label: 'Expected pay',
                        value: AppFormat.money(application.expectedPay!),
                        icon: Icons.currency_rupee_rounded,
                      ),
                    if (application.message.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      const OverlineLabel('Message'),
                      const SizedBox(height: 4),
                      Text(application.message, style: texts.body),
                    ],
                  ],
                ),
              ),
              if (application.status == ApplicationStatus.accepted &&
                  job != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  color: AppColors.successSurface,
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.celebration_rounded,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'You got this job. Check in on the day of work.',
                          style: texts.label,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Open accepted job',
                  icon: Icons.work_rounded,
                  onPressed: () => AppRouter.push(
                    context,
                    AppRoutes.acceptedJob,
                    arguments: job.id,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    final List<_Step> steps = <_Step>[
      _Step(
        'Applied',
        Icons.send_rounded,
        application.appliedAt == null
            ? null
            : AppFormat.dayMonthYear(application.appliedAt!),
        application.appliedAt != null,
      ),
      _Step(
        'Viewed by giver',
        Icons.visibility_rounded,
        application.viewedAt == null
            ? null
            : AppFormat.dayMonthYear(application.viewedAt!),
        application.viewedAt != null,
      ),
      _Step(
        'Shortlisted',
        Icons.star_rounded,
        application.shortlistedAt == null
            ? null
            : AppFormat.dayMonthYear(application.shortlistedAt!),
        application.shortlistedAt != null,
      ),
      _Step(
        'Accepted',
        Icons.check_circle_rounded,
        application.acceptedAt == null
            ? null
            : AppFormat.dayMonthYear(application.acceptedAt!),
        application.acceptedAt != null,
      ),
    ];

    return Column(
      children: <Widget>[
        for (int index = 0; index < steps.length; index++)
          _TimelineRow(step: steps[index], isLast: index == steps.length - 1),
      ],
    );
  }
}

class _Step {
  const _Step(this.title, this.icon, this.date, this.done);

  final String title;
  final IconData icon;
  final String? date;
  final bool done;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.isLast});

  final _Step step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final Color color = step.done ? context.primary : AppColors.borderStrong;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: step.done
                      ? context.primaryTint
                      : AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.4),
                ),
                child: Icon(step.icon, size: 15, color: color),
              ),
              if (!isLast)
                Expanded(child: Container(width: 1.6, color: AppColors.border)),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    step.title,
                    style: texts.label?.copyWith(
                      color: step.done
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                  if (step.date != null) Text(step.date!, style: texts.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
