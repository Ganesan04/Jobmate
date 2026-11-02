import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/enums.dart';
import '../../../models/user.dart';
import '../../../state/auth_provider.dart';

/// Verification centre: trust score plus per-item submission and status.
///
/// Verification belongs to the person, not the mode, so the same checklist and
/// badge show whether the account is working or hiring.
class VerificationCentreScreen extends StatelessWidget {
  const VerificationCentreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final AuthProvider auth = context.watch<AuthProvider>();
    final List<VerificationRecord> records = auth.verifications;
    final VerificationSummary summary = auth.verificationSummary;

    return AppScaffold(
      appBar: const AppTopBar(title: 'Verification centre'),
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
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _ScoreRing(ratio: summary.ratio),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Trust score', style: texts.label),
                          const SizedBox(height: 2),
                          Text(
                            '${(summary.ratio * 100).round()}% verified',
                            style: texts.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Counts for both finding work and hiring.',
                            style: texts.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StatusChip.neutral(
                        '${summary.verifiedCount} of ${summary.all.length} verified',
                        icon: Icons.verified_rounded,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Verify your details'),
          const SizedBox(height: AppSpacing.xs),
          for (final VerificationRecord record in records)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _VerificationTile(
                record: record,
                onSubmit: () => _submit(context, record),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          const InfoBanner(
            message:
                'Jobmate never stores your documents on the device. A real build would upload '
                'them to a secure, encrypted service.',
            icon: Icons.lock_rounded,
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context, VerificationRecord record) async {
    if (record.status == VerificationStatus.verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${record.type.label} is already verified')),
      );
      return;
    }
    final String? documentName = await showInputDialog(
      context,
      title: 'Submit ${record.type.label.toLowerCase()}',
      message: 'Enter the document name you will upload (e.g. Aadhaar card).',
      label: 'Document name',
      initialValue: switch (record.type) {
        VerificationType.identity => 'Aadhaar card',
        VerificationType.email => 'Email link',
        VerificationType.skills => 'Skill proof',
        VerificationType.address => 'Address proof',
        VerificationType.phone => 'Phone OTP',
      },
    );
    if (documentName == null ||
        documentName.trim().isEmpty ||
        !context.mounted) {
      return;
    }
    final AuthProvider auth = context.read<AuthProvider>();
    final bool ok = await auth.submitVerification(
      record.type,
      documentName: documentName.trim(),
    );
    if (!context.mounted) return;
    if (ok) {
      await showSuccessDialog(
        context,
        title: '${record.type.label} verified',
        message: 'Your badge is updated for both finding work and hiring.',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Could not submit. Try again.')),
      );
    }
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox(
            width: 68,
            height: 68,
            child: CircularProgressIndicator(
              value: ratio == 0 ? 0.04 : ratio,
              strokeWidth: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(context.primary),
            ),
          ),
          Text(
            '${(ratio * 100).round()}%',
            style: Theme.of(context).textTheme.label,
          ),
        ],
      ),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  const _VerificationTile({required this.record, required this.onSubmit});

  final VerificationRecord record;
  final VoidCallback onSubmit;

  IconData get _icon {
    switch (record.type) {
      case VerificationType.identity:
        return Icons.badge_rounded;
      case VerificationType.phone:
        return Icons.phone_iphone_rounded;
      case VerificationType.email:
        return Icons.alternate_email_rounded;
      case VerificationType.skills:
        return Icons.workspace_premium_rounded;
      case VerificationType.address:
        return Icons.home_work_rounded;
    }
  }

  Color get _color {
    switch (record.status) {
      case VerificationStatus.verified:
        return AppColors.success;
      case VerificationStatus.pending:
        return AppColors.warning;
      case VerificationStatus.rejected:
        return AppColors.error;
      case VerificationStatus.notVerified:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color.lerp(_color, Colors.white, 0.86),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(_icon, size: 20, color: _color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(record.type.label, style: texts.label),
                    const SizedBox(height: 2),
                    Text(
                      record.documentName.isNotEmpty
                          ? record.documentName
                          : record.note,
                      style: texts.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              StatusChip.neutral(
                record.status.label,
                color: _color,
                icon: record.status == VerificationStatus.verified
                    ? Icons.verified_rounded
                    : null,
              ),
            ],
          ),
          if (record.submittedOn != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Submitted ${record.submittedOn!.toLocal().toString().split('.').first}',
              style: texts.caption,
            ),
          ],
          if (record.status == VerificationStatus.notVerified ||
              record.status == VerificationStatus.rejected) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: 'Submit for verification',
              icon: Icons.upload_rounded,
              onPressed: onSubmit,
            ),
          ],
        ],
      ),
    );
  }
}
