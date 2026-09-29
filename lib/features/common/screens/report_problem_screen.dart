import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/enums.dart';
import '../../../models/support.dart';
import '../../../state/support_provider.dart';

/// Report a problem or safety issue: reason, related job and details.
class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _details = TextEditingController();
  final TextEditingController _job = TextEditingController();
  ReportReason? _reason;
  SupportReport? _report;

  @override
  void dispose() {
    _details.dispose();
    _job.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose what you want to report')),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final SupportProvider support = context.read<SupportProvider>();
    final SupportReport? report = await support.submitReport(
      reason: _reason!,
      details: _details.text.trim(),
      relatedJob: _job.text.trim(),
    );
    if (!mounted) return;
    if (report == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit the report. Please try again.'),
        ),
      );
      return;
    }
    setState(() => _report = report);
    await showSuccessDialog(
      context,
      title: 'Report submitted',
      message:
          'Reference ${report.id}. Our team usually responds within 24 hours.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final SupportProvider support = context.watch<SupportProvider>();

    return AppScaffold(
      appBar: const AppTopBar(title: 'Report a problem'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xs,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          children: <Widget>[
            const InfoBanner(
              message:
                  'Safety issues are reviewed first. If anyone is in immediate danger, call the '
                  'local emergency number.',
              icon: Icons.shield_rounded,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            const RequiredLabel(text: 'What are you reporting?'),
            ChipWrap(
              children: ReportReason.values
                  .map(
                    (ReportReason reason) => SelectableChip(
                      label: reason.label,
                      selected: _reason == reason,
                      onTap: () => setState(() => _reason = reason),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            const RequiredLabel(text: 'Related job', optional: true),
            AppTextField(
              controller: _job,
              hint: 'e.g. Packing helper — Koramangala',
              prefixIcon: Icons.work_outline_rounded,
              enabled: _report == null && !support.submitting,
            ),
            const SizedBox(height: AppSpacing.md),
            const RequiredLabel(text: 'Tell us what happened'),
            AppTextField(
              controller: _details,
              hint: 'Include dates, amounts and names where possible',
              maxLines: 5,
              minLines: 4,
              enabled: _report == null && !support.submitting,
              validator: (String? value) =>
                  Validators.minLength(value, 20, field: 'Details'),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: _report == null ? 'Submit report' : 'Report submitted',
              icon: _report == null ? Icons.send_rounded : Icons.check_rounded,
              success: _report != null,
              loading: support.submitting,
              onPressed: _report != null || support.submitting ? null : _submit,
            ),
            if (_report != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              AppCard(
                color: AppColors.successSurface,
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Reference ${_report!.id}', style: texts.label),
                          Text(
                            'We will notify you by phone',
                            style: texts.caption,
                          ),
                        ],
                      ),
                    ),
                    StatusChip.neutral('Open', icon: Icons.pending_rounded),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
