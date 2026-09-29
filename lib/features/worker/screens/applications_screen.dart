import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/widgets/application_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/application.dart';
import '../../../models/enums.dart';
import '../../../models/job.dart';
import '../../../navigation/app_router.dart';
import '../../../state/job_feed_provider.dart';
import '../../../state/worker_provider.dart';

/// My applications split into Active and Closed groups, with a status filter.
class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  static const List<ApplicationStatus> _activeStatuses = <ApplicationStatus>[
    ApplicationStatus.applied,
    ApplicationStatus.viewed,
    ApplicationStatus.shortlisted,
    ApplicationStatus.accepted,
  ];
  static const List<ApplicationStatus> _closedStatuses = <ApplicationStatus>[
    ApplicationStatus.rejected,
    ApplicationStatus.withdrawn,
    ApplicationStatus.expired,
  ];

  ApplicationStatus? _filter;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    final WorkerProvider worker = context.read<WorkerProvider>();
    if (worker.applications.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => worker.load());
    }
  }

  List<JobApplication> _filtered(WorkerProvider worker) {
    final List<JobApplication> all = worker.applications;
    if (_filter == null) return all;
    return all.where((JobApplication a) => a.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final WorkerProvider worker = context.watch<WorkerProvider>();
    final List<JobApplication> items = _filtered(worker);

    return AppScaffold(
      appBar: const AppTopBar(title: 'My applications'),
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
                    label: 'All',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                ),
                for (final ApplicationStatus status in ApplicationStatus.values)
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
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: worker.isLoading && worker.applications.isEmpty
                ? const SkeletonList(count: 3)
                : worker.hasError && worker.applications.isEmpty
                ? ErrorStateView(
                    message: 'Could not load applications',
                    onRetry: worker.retry,
                  )
                : items.isEmpty
                ? EmptyStateView(
                    title: 'No applications yet',
                    message: 'Apply to jobs and track their status here.',
                    icon: Icons.send_rounded,
                    actionLabel: 'Find work',
                    onAction: () => AppRouter.pushReplacement(
                      context,
                      AppRoutes.searchJobs,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => worker.load(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        AppSpacing.xs,
                        AppSpacing.screen,
                        AppSpacing.xl,
                      ),
                      children: <Widget>[
                        Text(
                          '${items.length} application${items.length == 1 ? '' : 's'}',
                          style: texts.caption,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (_filter == null) ...<Widget>[
                          const SectionHeader(title: 'Active'),
                        ],
                        for (final JobApplication application in items.where(
                          (JobApplication a) =>
                              _activeStatuses.contains(a.status),
                        ))
                          _ApplicationTile(application: application),
                        if (_filter == null &&
                            items.any(
                              (JobApplication a) =>
                                  _closedStatuses.contains(a.status),
                            )) ...<Widget>[
                          const SizedBox(height: AppSpacing.md),
                          const SectionHeader(title: 'Closed'),
                        ],
                        for (final JobApplication application in items.where(
                          (JobApplication a) =>
                              _closedStatuses.contains(a.status),
                        ))
                          _ApplicationTile(application: application),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  const _ApplicationTile({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    final JobFeedProvider feed = context.read<JobFeedProvider>();
    return FutureBuilder<Job>(
      future: feed.jobById(application.jobId),
      builder: (BuildContext context, AsyncSnapshot<Job> snapshot) {
        final Job? job = snapshot.data;
        if (job == null) return const SizedBox(height: AppSpacing.sm);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ApplicationCard(
            application: application,
            job: job,
            onTap: () => AppRouter.push(
              context,
              AppRoutes.applicationDetails,
              arguments: application.id,
            ),
            onWithdraw:
                application.status == ApplicationStatus.applied ||
                    application.status == ApplicationStatus.viewed
                ? () => _confirmWithdraw(context, application)
                : null,
          ),
        );
      },
    );
  }

  Future<void> _confirmWithdraw(
    BuildContext context,
    JobApplication application,
  ) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Withdraw application?',
      message:
          'The work giver will no longer see your application for this job.',
      confirmLabel: 'Withdraw',
      destructive: true,
      icon: Icons.undo_rounded,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<WorkerProvider>().withdraw(application);
  }
}
