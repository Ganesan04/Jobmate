import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/application.dart';
import '../../../models/job.dart';
import '../../../navigation/app_router.dart';
import '../../../state/job_feed_provider.dart';
import '../../../state/worker_provider.dart';

/// Confirmed booking for the worker: report time, check-in code entry, contact
/// details and payment status.
class AcceptedJobScreen extends StatefulWidget {
  const AcceptedJobScreen({super.key, required this.jobId});

  final String jobId;

  @override
  State<AcceptedJobScreen> createState() => _AcceptedJobScreenState();
}

class _AcceptedJobScreenState extends State<AcceptedJobScreen> {
  final TextEditingController _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  WorkerAssignment? _assignmentFor(List<WorkerAssignment> assignments) {
    for (final WorkerAssignment assignment in assignments) {
      if (assignment.jobId == widget.jobId) return assignment;
    }
    return assignments.isEmpty ? null : assignments.first;
  }

  Future<void> _checkIn(WorkerAssignment assignment) async {
    FocusScope.of(context).unfocus();
    if (_code.text.trim().length != 4) {
      setState(() => _error = 'Enter the 4-digit check-in code');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final String? failure = await context.read<WorkerProvider>().checkIn(
      assignment,
      _code.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = failure;
    });
    if (failure == null) {
      await showSuccessDialog(
        context,
        title: 'Checked in',
        message: 'Your check-in has been recorded. Have a great shift!',
        primaryLabel: 'Done',
      );
    }
  }

  Future<void> _completeShift(WorkerAssignment assignment) async {
    setState(() => _busy = true);
    final String? failure = await context.read<WorkerProvider>().completeShift(
      assignment,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = failure;
    });
    if (failure == null) {
      await showSuccessDialog(
        context,
        title: 'Shift completed',
        message:
            'The work giver has been notified. Payment shows under Earnings '
            'once it is released.',
        primaryLabel: 'Done',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final WorkerProvider worker = context.watch<WorkerProvider>();
    final JobFeedProvider feed = context.watch<JobFeedProvider>();
    final WorkerAssignment? assignment = _assignmentFor(worker.assignments);

    return FutureBuilder<Job>(
      future: feed.jobById(widget.jobId),
      builder: (BuildContext context, AsyncSnapshot<Job> snapshot) {
        final Job? job = snapshot.data;
        if (job == null && !snapshot.hasData) {
          return const AppScaffold(
            appBar: AppTopBar(title: 'Accepted job'),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (assignment == null) {
          return AppScaffold(
            appBar: const AppTopBar(title: 'Accepted job'),
            body: EmptyStateView(
              title: 'No active booking',
              message: 'This job is not currently confirmed for you.',
              icon: Icons.event_busy_rounded,
              actionLabel: 'My applications',
              onAction: () =>
                  AppRouter.pushReplacement(context, AppRoutes.applications),
            ),
          );
        }

        return AppScaffold(
          appBar: const AppTopBar(title: 'Accepted job'),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xs,
              AppSpacing.screen,
              AppSpacing.xl,
            ),
            children: <Widget>[
              AppCard(
                elevated: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(job?.title ?? 'Confirmed job', style: texts.headline),
                    const SizedBox(height: 2),
                    Text(job?.company ?? '', style: texts.bodyMedium),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: <Widget>[
                        StatusChip.payment(assignment.paymentStatus),
                        StatusChip.neutral(
                          assignment.isCheckedIn
                              ? 'Checked in'
                              : 'Not checked in',
                          icon: assignment.isCheckedIn
                              ? Icons.verified_rounded
                              : Icons.schedule_rounded,
                        ),
                      ],
                    ),
                    if (job != null) ...<Widget>[
                      if (assignment.isCheckedIn &&
                          assignment.completedAt == null) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        AppCard(
                          color: AppColors.successSurface,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const SectionHeader(
                                title: 'Finish the shift',
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Checked in. Mark the shift complete once the work is '
                                'done so the work giver can release your payment.',
                                style: texts.caption,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (_error != null) ...<Widget>[
                                Text(
                                  _error!,
                                  style: texts.caption?.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                              ],
                              SecondaryButton(
                                label: 'Mark shift complete',
                                icon: Icons.task_alt_rounded,
                                onPressed: _busy
                                    ? null
                                    : () => _completeShift(assignment),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        AppFormat.money(assignment.agreedPay),
                        style: texts.display?.copyWith(color: context.primary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (job != null)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SectionHeader(
                        title: 'Shift details',
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      InfoRow(
                        label: 'Date',
                        value: AppFormat.weekdayDate(job.date),
                        icon: Icons.calendar_today_rounded,
                        bold: true,
                      ),
                      InfoRow(
                        label: 'Report time',
                        value: job.reportTime,
                        icon: Icons.schedule_rounded,
                        bold: true,
                      ),
                      InfoRow(
                        label: 'Shift',
                        value: job.timeRange,
                        icon: Icons.timelapse_rounded,
                      ),
                      InfoRow(
                        label: 'Area',
                        value: job.area,
                        icon: Icons.location_on_outlined,
                      ),
                      if (job.address.isNotEmpty)
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
                    ],
                  ),
                ),
              if (!assignment.isCheckedIn) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  color: context.primaryTint,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SectionHeader(
                        title: 'Check in',
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter the code shared by the work giver when you reach the site.',
                        style: texts.caption,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        controller: _code,
                        hint: '4-digit code',
                        prefixIcon: Icons.pin_rounded,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        enabled: !_busy,
                        errorText: _error,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (String value) => _checkIn(assignment),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      PrimaryButton(
                        label: 'Check in now',
                        icon: Icons.login_rounded,
                        loading: _busy,
                        onPressed: _busy ? null : () => _checkIn(assignment),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const InfoBanner(
                        message:
                            'Demo: use code 1234 to check in, or 9999 to see the error state.',
                        icon: Icons.science_rounded,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionHeader(
                      title: 'Payment',
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    InfoRow(
                      label: 'Agreed pay',
                      value: AppFormat.money(assignment.agreedPay),
                      icon: Icons.currency_rupee_rounded,
                      bold: true,
                    ),
                    InfoRow(
                      label: 'Status',
                      value: assignment.paymentStatus.label,
                      icon: Icons.account_balance_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SecondaryButton(
                      label: 'Report a payment problem',
                      icon: Icons.flag_outlined,
                      onPressed: () =>
                          AppRouter.push(context, AppRoutes.reportProblem),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: StickyActionBar(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: SecondaryButton(
                    label: 'Message',
                    icon: Icons.chat_bubble_outline_rounded,
                    onPressed: () =>
                        AppRouter.push(context, AppRoutes.messages),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(
                    label: 'Earnings',
                    icon: Icons.payments_rounded,
                    onPressed: () =>
                        AppRouter.push(context, AppRoutes.earnings),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
