import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/application_card.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/application.dart';
import '../../../models/enums.dart';
import '../../../models/job.dart';
import '../../../navigation/app_router.dart';
import '../../../state/giver_provider.dart';

/// Applicants for one job with shortlist / reject / select actions and a sticky
/// "confirm selection" bar.
class JobApplicationsScreen extends StatefulWidget {
  const JobApplicationsScreen({super.key, required this.jobId});

  final String jobId;

  @override
  State<JobApplicationsScreen> createState() => _JobApplicationsScreenState();
}

class _JobApplicationsScreenState extends State<JobApplicationsScreen> {
  ApplicantStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final GiverProvider giver = context.watch<GiverProvider>();
    final List<JobApplicant> all = giver.applicantsForJob(widget.jobId);
    final List<JobApplicant> items = _filter == null
        ? all
        : all.where((JobApplicant a) => a.status == _filter).toList();
    final Job? job = giver.myJobs
        .where((Job j) => j.id == widget.jobId)
        .firstOrNull;
    final int selected = giver.selectedCount(widget.jobId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppScaffold(
        centerContent: false,
        appBar: const AppTopBar(title: 'Applicants'),
        body: Column(
          children: <Widget>[
            if (job != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.xs,
                  AppSpacing.screen,
                  AppSpacing.sm,
                ),
                child: AppCard(
                  color: context.primaryTint,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(job.title, style: texts.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${AppFormat.weekdayDate(job.date)} • ${job.timeRange}',
                        style: texts.caption,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      InfoRow(
                        label: 'Slots',
                        value: '$selected of ${job.workersNeeded} filled',
                        icon: Icons.groups_rounded,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: SelectableChip(
                      label: 'All (${all.length})',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                  ),
                  for (final ApplicantStatus status in ApplicantStatus.values)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: SelectableChip(
                        label: status.label,
                        selected: _filter == status,
                        onTap: () => setState(() => _filter = status),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? EmptyStateView(
                      title: all.isEmpty ? 'No applicants yet' : 'Nothing here',
                      message: all.isEmpty
                          ? 'Workers who apply to this job will appear here.'
                          : 'No applicants match this filter.',
                      icon: Icons.people_outline_rounded,
                      compact: true,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        AppSpacing.xs,
                        AppSpacing.screen,
                        AppSpacing.xl,
                      ),
                      children: <Widget>[
                        SectionHeader(title: '${items.length} applicant(s)'),
                        for (final JobApplicant applicant in items)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: ApplicantCard(
                              applicant: applicant,
                              job: job ?? _placeholderJob,
                              onShortlist: () => giver.updateApplicant(
                                applicant.id,
                                ApplicantStatus.shortlisted,
                              ),
                              onReject: () => giver.updateApplicant(
                                applicant.id,
                                ApplicantStatus.rejected,
                              ),
                              onSelect: () => AppRouter.push(
                                context,
                                AppRoutes.selectWorker,
                                arguments: <String, dynamic>{
                                  'jobId': widget.jobId,
                                  'applicantId': applicant.id,
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
        bottomNavigationBar: job == null
            ? null
            : StickyActionBar(
                child: PrimaryButton(
                  label: selected > 0
                      ? 'Pay $selected worker(s)'
                      : 'Select workers',
                  icon: selected > 0
                      ? Icons.payments_rounded
                      : Icons.how_to_reg_rounded,
                  onPressed: all.isEmpty
                      ? null
                      : () => AppRouter.push(
                          context,
                          AppRoutes.selectWorker,
                          arguments: <String, dynamic>{
                            'jobId': widget.jobId,
                            'applicantId': null,
                          },
                        ),
                ),
              ),
      ),
    );
  }

  /// Minimal job used only when a deleted job still has cached applicants.
  static final Job _placeholderJob = Job(
    id: 'unknown',
    title: 'Job',
    company: '',
    giverId: '',
    category: JobCategory.other,
    description: '',
    date: DateTime(2026),
    startTime: '',
    endTime: '',
    reportTime: '',
    pay: 0,
    payType: PayType.daily,
    workersNeeded: 1,
    workersFilled: 0,
    area: '',
    address: '',
    applicants: 0,
    skills: const <String>[],
    experience: '',
    distanceKm: 0,
  );
}
