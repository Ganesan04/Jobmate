import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/application.dart';
import '../../../models/job.dart';
import '../../../navigation/app_router.dart';
import '../../../state/job_feed_provider.dart';
import '../../../state/worker_provider.dart';

/// Apply to a job: summary, message, expected pay and availability.
class ApplyScreen extends StatefulWidget {
  const ApplyScreen({super.key, required this.jobId});

  final String jobId;

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _message = TextEditingController(
    text: 'I am available for this work and can report on time.',
  );
  final TextEditingController _expectedPay = TextEditingController();
  String _availability = 'Immediately available';
  bool _busy = false;
  bool _done = false;
  String? _error;
  Job? _job;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _message.dispose();
    _expectedPay.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final Job job = await context.read<JobFeedProvider>().jobById(
        widget.jobId,
      );
      if (mounted) setState(() => _job = job);
    } catch (_) {
      if (mounted) setState(() => _job = null);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final Job? job = _job;
    if (job == null) return;
    setState(() => _busy = true);
    final JobApplication? created = await context.read<WorkerProvider>().apply(
      job: job,
      message: _message.text.trim(),
      expectedPay: int.tryParse(_expectedPay.text),
      availability: _availability,
    );
    if (!mounted) return;
    if (created == null) {
      setState(() {
        _busy = false;
        _error = 'You have already applied for this job.';
      });
      return;
    }
    setState(() {
      _busy = false;
      _done = true;
    });
    await showSuccessDialog(
      context,
      title: 'Application sent',
      message:
          'The work giver has been notified. You can track the status under '
          'My applications.',
      primaryLabel: 'View applications',
      onPrimary: () {
        Navigator.of(context).pop();
        AppRouter.pushReplacement(context, AppRoutes.applications);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final Job? job = _job;

    return AppScaffold(
      appBar: const AppTopBar(title: 'Apply for job'),
      body: job == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.xs,
                  AppSpacing.screen,
                  AppSpacing.xl,
                ),
                children: <Widget>[
                  if (_error != null) ...<Widget>[
                    ErrorBanner(
                      message: _error!,
                      onDismiss: () {
                        setState(() => _error = null);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  AppCard(
                    color: context.primaryTint,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(job.title, style: texts.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '${job.company} • ${AppFormat.weekdayDate(job.date)}',
                          style: texts.caption,
                        ),
                        const SizedBox(height: AppSpacing.sm),
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
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const RequiredLabel(text: 'Message to the work giver'),
                  AppTextField(
                    controller: _message,
                    hint: 'Introduce yourself and mention your experience',
                    maxLines: 4,
                    minLines: 3,
                    enabled: !_busy && !_done,
                    validator: (String? value) =>
                        Validators.minLength(value, 10, field: 'Message'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const RequiredLabel(
                    text: 'Expected pay (per day)',
                    optional: true,
                  ),
                  AppTextField(
                    controller: _expectedPay,
                    hint:
                        'Leave blank to accept ${AppFormat.money(job.totalPayout)}',
                    prefixIcon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      DigitsOnlyFormatter(maxLength: 5),
                    ],
                    enabled: !_busy && !_done,
                    validator: (String? value) {
                      if ((value ?? '').isEmpty) return null;
                      return Validators.amount(value, min: 100, max: 99999);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const RequiredLabel(text: 'Availability'),
                  ChipWrap(
                    children:
                        <String>[
                              'Immediately available',
                              'Available tomorrow',
                              'Available this weekend',
                            ]
                            .map(
                              (String option) => SelectableChip(
                                label: option,
                                selected: _availability == option,
                                onTap: () =>
                                    setState(() => _availability = option),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    color: AppColors.surfaceMuted,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SectionHeader(
                          title: 'What happens next',
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const InfoRow(
                          label: '1',
                          value:
                              'The work giver reviews your profile and message',
                          icon: Icons.visibility_rounded,
                        ),
                        const InfoRow(
                          label: '2',
                          value: 'You are notified if you are shortlisted',
                          icon: Icons.star_rounded,
                        ),
                        const InfoRow(
                          label: '3',
                          value: 'Accept the offer to get the job booked',
                          icon: Icons.check_circle_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: _done ? 'Application sent' : 'Send application',
                    icon: _done ? Icons.check_rounded : Icons.send_rounded,
                    success: _done,
                    loading: _busy,
                    onPressed: _busy || _done ? null : _submit,
                  ),
                ],
              ),
            ),
    );
  }
}
