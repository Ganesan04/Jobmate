import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/application_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/application.dart';
import '../../../models/enums.dart';
import '../../../models/job.dart';
import '../../../navigation/app_router.dart';
import '../../../state/giver_provider.dart';

/// Selection mode: pick up to [Job.workersNeeded] workers, agree a pay for each
/// and confirm the booking.
class SelectWorkerScreen extends StatefulWidget {
  const SelectWorkerScreen({super.key, required this.jobId, this.applicantId});

  final String jobId;
  final String? applicantId;

  @override
  State<SelectWorkerScreen> createState() => _SelectWorkerScreenState();
}

class _SelectWorkerScreenState extends State<SelectWorkerScreen> {
  final Map<String, int> _agreedPays = <String, int>{};
  bool _busy = false;

  int get _selectedCount => _agreedPays.length;

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final GiverProvider giver = context.watch<GiverProvider>();
    final List<JobApplicant> applicants = giver.applicantsForJob(widget.jobId);
    final Job? job = giver.myJobs
        .where((Job j) => j.id == widget.jobId)
        .firstOrNull;
    final int slots = job?.workersNeeded ?? 1;
    final bool full = _selectedCount >= slots;

    return AppScaffold(
      appBar: AppTopBar(
        title: 'Select workers',
        subtitle: job == null ? null : '${job.workersNeeded} slot(s) available',
      ),
      body: applicants.isEmpty
          ? EmptyStateView(
              title: 'No applicants',
              message: 'Wait for workers to apply before selecting them.',
              icon: Icons.people_outline_rounded,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.xs,
                AppSpacing.screen,
                110,
              ),
              children: <Widget>[
                const InfoBanner(
                  message:
                      'Select up to the required number of workers. You can agree a different '
                      'pay for each worker before confirming.',
                  icon: Icons.info_outline_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                SectionHeader(title: 'Applicants'),
                const SizedBox(height: AppSpacing.xs),
                for (final JobApplicant applicant in applicants)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Column(
                      children: <Widget>[
                        ApplicantCard(
                          applicant: applicant,
                          job: job ?? _fallbackJob,
                          selectionMode: true,
                          isSelected: _agreedPays.containsKey(applicant.id),
                          selectionLocked:
                              full && !_agreedPays.containsKey(applicant.id),
                          onToggleSelect: () => _toggle(applicant, job),
                        ),
                        if (_agreedPays.containsKey(applicant.id) &&
                            job != null)
                          _PayRow(
                            workerName: applicant.worker.name,
                            amount: _agreedPays[applicant.id]!,
                            base: job.pay,
                            onEdit: () => _editPay(applicant, job),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: AppShadows.raised,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '$_selectedCount of $slots selected',
                      style: texts.label,
                    ),
                    Text(
                      AppFormat.money(
                        _agreedPays.values.fold<int>(
                          0,
                          (int a, int b) => a + b,
                        ),
                      ),
                      style: texts.caption,
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(
                    label: 'Confirm selection',
                    icon: Icons.check_rounded,
                    loading: _busy,
                    onPressed: _selectedCount == 0 || _busy
                        ? null
                        : () => _confirm(job),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static final Job _fallbackJob = Job(
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
    pay: 500,
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

  void _toggle(JobApplicant applicant, Job? job) {
    setState(() {
      if (_agreedPays.containsKey(applicant.id)) {
        _agreedPays.remove(applicant.id);
      } else {
        _agreedPays[applicant.id] =
            applicant.proposedPay ?? applicant.expectedPay ?? job?.pay ?? 500;
      }
    });
  }

  Future<void> _editPay(JobApplicant applicant, Job job) async {
    final TextEditingController controller = TextEditingController(
      text: '${_agreedPays[applicant.id]}',
    );
    final int? value = await showAppSheet<int>(
      context: context,
      title: 'Agree pay for ${applicant.worker.name}',
      subtitle: 'Posted pay: ${AppFormat.money(job.pay)} per day',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.md,
          AppSpacing.screen,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppTextField(
              controller: controller,
              label: 'Agreed pay',
              prefixIcon: Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Save pay',
              onPressed: () => Navigator.of(
                context,
              ).pop(int.tryParse(controller.text.trim())),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (value != null && value > 0) {
      setState(() => _agreedPays[applicant.id] = value);
      if (mounted) {
        await context.read<GiverProvider>().proposePay(applicant.id, value);
      }
    }
  }

  Future<void> _confirm(Job? job) async {
    setState(() => _busy = true);
    final GiverProvider giver = context.read<GiverProvider>();
    await giver.confirmSelection(jobId: widget.jobId, agreedPays: _agreedPays);
    if (!mounted) return;
    setState(() => _busy = false);
    await showSuccessDialog(
      context,
      title: 'Workers confirmed',
      message:
          '$_selectedCount worker(s) have been booked for this job. '
          'Complete the work, then release the payment.',
      primaryLabel: 'View applicants',
      onPrimary: () {
        Navigator.of(context).pop();
        AppRouter.pushReplacement(
          context,
          AppRoutes.jobApplications,
          arguments: widget.jobId,
        );
      },
    );
  }
}

class _PayRow extends StatelessWidget {
  const _PayRow({
    required this.workerName,
    required this.amount,
    required this.base,
    required this.onEdit,
  });

  final String workerName;
  final int amount;
  final int base;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: -AppSpacing.xs),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
        ),
        color: AppColors.surfaceMuted,
        child: Row(
          children: <Widget>[
            Icon(Icons.payments_rounded, size: 17, color: context.primary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Agreed pay for $workerName: ${AppFormat.money(amount)}'
                '${amount == base ? '' : ' (posted ${AppFormat.money(base)})'}',
                style: Theme.of(context).textTheme.caption,
              ),
            ),
            TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              ),
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }
}
