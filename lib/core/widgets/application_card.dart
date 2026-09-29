import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/application.dart';
import '../../models/enums.dart';
import '../../models/job.dart';
import '../../models/user.dart';
import 'app_card.dart';
import 'profile_avatar.dart';
import 'status_chip.dart';
import '../utils/context_extensions.dart';

/// Worker-facing application card: job summary + status + applied date.
class ApplicationCard extends StatelessWidget {
  const ApplicationCard({
    super.key,
    required this.application,
    required this.job,
    this.onTap,
    this.onWithdraw,
    this.trailing,
  });

  final JobApplication application;
  final Job job;
  final VoidCallback? onTap;
  final VoidCallback? onWithdraw;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ApplicationStatus status = application.status;

    return AppCard(
      onTap: onTap,
      semanticLabel: '${job.title}, application ${status.label}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color.lerp(scheme.primary, Colors.white, 0.88),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(job.category.icon, size: 20, color: scheme.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: texts.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: texts.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              StatusChip.application(status, dense: true),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: _Detail(
                  icon: Icons.calendar_today_rounded,
                  label: AppFormat.relativeDay(job.date),
                ),
              ),
              Expanded(
                child: _Detail(
                  icon: Icons.schedule_rounded,
                  label: job.startTime,
                ),
              ),
              Expanded(
                child: _Detail(
                  icon: Icons.payments_rounded,
                  label: AppFormat.money(job.pay),
                  highlight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const AppDivider(),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              Icon(
                Icons.how_to_reg_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 5),
              Text(
                'Applied ${AppFormat.timeAgo(application.appliedDate)}',
                style: texts.caption,
              ),
              const Spacer(),
              if (trailing case final Widget widget) widget,
              if (onWithdraw != null && status.isOpen)
                TextButton(
                  onPressed: onWithdraw,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Withdraw'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Giver-facing applicant card with rating, skills, pay and actions.
class ApplicantCard extends StatelessWidget {
  const ApplicantCard({
    super.key,
    required this.applicant,
    required this.job,
    this.onShortlist,
    this.onReject,
    this.onSelect,
    this.onViewProfile,
    this.onPay,
    this.selectionMode = false,
    this.isSelected = false,
    this.onToggleSelect,
    this.selectionLocked = false,
  });

  final JobApplicant applicant;
  final Job job;
  final VoidCallback? onShortlist;
  final VoidCallback? onReject;
  final VoidCallback? onSelect;
  final VoidCallback? onViewProfile;
  final VoidCallback? onPay;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onToggleSelect;
  final bool selectionLocked;

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final UserProfile worker = applicant.worker;

    return AppCard(
      onTap: selectionMode ? onToggleSelect : onViewProfile,
      borderColor: isSelected ? scheme.primary : null,
      color: isSelected
          ? (Color.lerp(scheme.primary, Colors.white, 0.95) ??
                AppColors.surface)
          : AppColors.surface,
      semanticLabel:
          '${applicant.worker.name}, rating ${applicant.worker.rating}, status ${applicant.status.label}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs, top: 14),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 22,
                    color: isSelected ? scheme.primary : AppColors.borderStrong,
                  ),
                ),
              ProfileAvatar.user(worker),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            worker.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: texts.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: <Widget>[
                        RatingStars(rating: worker.rating),
                        const SizedBox(width: 5),
                        Text(
                          '${worker.jobsCompleted} jobs',
                          style: texts.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${worker.area} • ${AppFormat.distance(applicant.distanceKm)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: texts.caption,
                    ),
                  ],
                ),
              ),
              _ApplicantStatusChip(status: applicant.status),
            ],
          ),
          if (applicant.worker.skills.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            ChipWrap(
              children: applicant.worker.skills
                  .take(3)
                  .map((String skill) => StatusChip.neutral(skill))
                  .toList(),
            ),
          ],
          if (applicant.message.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                '"${applicant.message}"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: texts.caption?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Offered pay', style: texts.labelSmall),
                  Text(
                    AppFormat.money(applicant.proposedPay ?? job.pay),
                    style: texts.titleMedium?.copyWith(color: scheme.primary),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Availability', style: texts.labelSmall),
                  Text(
                    applicant.appliedAt == null
                        ? 'Available now'
                        : 'Within 24 hrs',
                    style: texts.labelLarge,
                  ),
                ],
              ),
              const Spacer(),
              if (selectionMode)
                Text(
                  AppFormat.timeAgo(applicant.appliedAt ?? DateTime.now()),
                  style: texts.labelSmall,
                ),
            ],
          ),
          if (!selectionMode) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            _ApplicantActions(
              applicant: applicant,
              onShortlist: onShortlist,
              onReject: onReject,
              onSelect: onSelect,
              onViewProfile: onViewProfile,
              onPay: onPay,
              selectionLocked: selectionLocked,
            ),
          ],
        ],
      ),
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 13});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.star_rounded, size: size + 2, color: AppColors.warning),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.caption?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ApplicantStatusChip extends StatelessWidget {
  const _ApplicantStatusChip({required this.status});

  final ApplicantStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ApplicantStatus.applied:
        return const StatusChip(
          label: 'Applied',
          color: AppColors.info,
          icon: Icons.send_rounded,
          dense: true,
        );
      case ApplicantStatus.shortlisted:
        return const StatusChip(
          label: 'Shortlisted',
          color: AppColors.warning,
          icon: Icons.star_rounded,
          dense: true,
        );
      case ApplicantStatus.selected:
        return const StatusChip(
          label: 'Selected',
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
          dense: true,
        );
      case ApplicantStatus.rejected:
        return const StatusChip(
          label: 'Rejected',
          color: AppColors.error,
          icon: Icons.cancel_rounded,
          dense: true,
        );
    }
  }
}

class _ApplicantActions extends StatelessWidget {
  const _ApplicantActions({
    required this.applicant,
    required this.onShortlist,
    required this.onReject,
    required this.onSelect,
    required this.onViewProfile,
    required this.onPay,
    required this.selectionLocked,
  });

  final JobApplicant applicant;
  final VoidCallback? onShortlist;
  final VoidCallback? onReject;
  final VoidCallback? onSelect;
  final VoidCallback? onViewProfile;
  final VoidCallback? onPay;
  final bool selectionLocked;

  @override
  Widget build(BuildContext context) {
    switch (applicant.status) {
      case ApplicantStatus.applied:
        return Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close_rounded, size: 17),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  minimumSize: const Size.fromHeight(42),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: FilledButton.icon(
                onPressed: onShortlist,
                icon: const Icon(Icons.star_rounded, size: 17),
                label: const Text('Shortlist'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                ),
              ),
            ),
          ],
        );
      case ApplicantStatus.shortlisted:
        return Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onViewProfile,
                icon: const Icon(Icons.person_outline_rounded, size: 17),
                label: const Text('Profile'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: onSelect,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
                label: const Text('Select worker'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                ),
              ),
            ),
          ],
        );
      case ApplicantStatus.selected:
        return Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPay,
                icon: const Icon(Icons.payments_rounded, size: 17),
                label: const Text('Pay now'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: FilledButton.icon(
                onPressed: onViewProfile,
                icon: const Icon(Icons.star_rounded, size: 17),
                label: const Text('Rate'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                ),
              ),
            ),
          ],
        );
      case ApplicantStatus.rejected:
        return OutlinedButton.icon(
          onPressed: onViewProfile,
          icon: const Icon(Icons.person_outline_rounded, size: 17),
          label: const Text('View profile'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(42),
            side: const BorderSide(color: AppColors.border),
          ),
        );
    }
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final Color color = highlight
        ? Theme.of(context).colorScheme.primary
        : AppColors.textSecondary;
    return Row(
      children: <Widget>[
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.caption?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
