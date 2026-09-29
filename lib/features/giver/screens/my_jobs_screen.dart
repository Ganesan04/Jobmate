import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/job_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/enums.dart';
import '../../../models/job.dart';
import '../../../navigation/app_router.dart';
import '../../../state/giver_provider.dart';

/// My Jobs: status tabs over the giver's own jobs with per-job applicant counts
/// and status actions.
class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  JobStatus? _status;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    final GiverProvider giver = context.read<GiverProvider>();
    if (giver.myJobs.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => giver.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final GiverProvider giver = context.watch<GiverProvider>();
    final List<Job> jobs = _status == null
        ? giver.myJobs
        : giver.myJobs.where((Job job) => job.status == _status).toList();

    return AppScaffold(
      appBar: const AppTopBar(title: 'My jobs'),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: SelectableChip(
                    label: 'All (${giver.myJobs.length})',
                    selected: _status == null,
                    onTap: () => setState(() => _status = null),
                  ),
                ),
                for (final JobStatus status in JobStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: SelectableChip(
                      label:
                          '${status.label} (${giver.jobsWithStatus(status).length})',
                      selected: _status == status,
                      onTap: () => setState(() => _status = status),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: giver.isLoading && giver.myJobs.isEmpty
                ? const JobCardSkeleton()
                : jobs.isEmpty
                ? EmptyStateView(
                    title: 'No jobs here',
                    message:
                        'Post a job to start receiving applications from workers.',
                    icon: Icons.post_add_rounded,
                    actionLabel: 'Post a job',
                    onAction: () =>
                        AppRouter.push(context, AppRoutes.createJob),
                  )
                : RefreshIndicator(
                    onRefresh: () => giver.load(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        AppSpacing.xs,
                        AppSpacing.screen,
                        AppSpacing.xl,
                      ),
                      children: <Widget>[
                        SectionHeader(
                          title:
                              '${jobs.length} job${jobs.length == 1 ? '' : 's'}',
                        ),
                        for (final Job job in jobs)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _GiverJobCard(giver: giver, job: job),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GiverJobCard extends StatelessWidget {
  const _GiverJobCard({required this.giver, required this.job});

  final GiverProvider giver;
  final Job job;

  @override
  Widget build(BuildContext context) {
    final int applicants = giver.applicantsForJob(job.id).length;
    final int toConfirm = giver
        .applicantsForJob(job.id)
        .where((dynamic a) => a.status == ApplicantStatus.shortlisted)
        .length;

    return JobCard(
      job: job,
      status: job.status,
      onTap: () =>
          AppRouter.push(context, AppRoutes.jobApplications, arguments: job.id),
      footer: Column(
        children: <Widget>[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              // Chips wrap so a long applicant count never overflows the card.
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    StatusChip.neutral(
                      '$applicants applicant${applicants == 1 ? '' : 's'}',
                      icon: Icons.people_alt_rounded,
                    ),
                    if (toConfirm > 0)
                      StatusChip.neutral(
                        '$toConfirm to confirm',
                        icon: Icons.pending_actions_rounded,
                        color: AppColors.warning,
                      )
                    else
                      StatusChip.neutral(
                        '${job.workersFilled}/${job.workersNeeded} filled',
                        icon: Icons.groups_rounded,
                      ),
                  ],
                ),
              ),
              if (job.status == JobStatus.active ||
                  job.status == JobStatus.inProgress)
                TextButton(
                  onPressed: () => _menu(context),
                  child: const Text('Manage'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _menu(BuildContext context) async {
    await showAppSheet<void>(
      context: context,
      title: job.title,
      subtitle: '${job.applicants} applicant(s)',
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.people_alt_rounded),
              title: const Text('View applicants'),
              onTap: () {
                Navigator.of(context).pop();
                AppRouter.push(
                  context,
                  AppRoutes.jobApplications,
                  arguments: job.id,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.pause_circle_outline_rounded),
              title: const Text('Mark as in progress'),
              onTap: () {
                Navigator.of(context).pop();
                giver.setJobStatus(job.id, JobStatus.inProgress);
              },
            ),
            ListTile(
              leading: const Icon(Icons.task_alt_rounded),
              title: const Text('Mark as completed'),
              onTap: () {
                Navigator.of(context).pop();
                giver.completeJob(job.id);
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel_rounded, color: AppColors.error),
              title: const Text('Cancel job'),
              onTap: () async {
                Navigator.of(context).pop();
                final bool confirmed = await showConfirmDialog(
                  context,
                  title: 'Cancel this job?',
                  message:
                      'Workers who applied will be notified that the job is cancelled.',
                  confirmLabel: 'Cancel job',
                  destructive: true,
                );
                if (confirmed) {
                  await giver.setJobStatus(job.id, JobStatus.cancelled);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
