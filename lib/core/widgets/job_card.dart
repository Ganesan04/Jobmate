import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/job.dart';
import 'app_card.dart';
import 'status_chip.dart';
import '../utils/context_extensions.dart';

/// The job card used across Worker Home, Search, Saved jobs, and giver views.
///
/// It is layout-flexible: the meta line drops items on narrow screens instead of
/// overflowing.
class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    this.onTap,
    this.onSave,
    this.isSaved = false,
    this.status,
    this.showAppliedBadge = false,
    this.footer,
    this.dense = false,
  });

  final Job job;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final bool isSaved;
  final JobStatus? status;
  final bool showAppliedBadge;
  final Widget? footer;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme texts = Theme.of(context).textTheme;
    final bool verified = job.contactPerson.isNotEmpty;

    return AppCard(
      onTap: onTap,
      semanticLabel:
          '${job.title} at ${job.company}, ${AppFormat.money(job.pay)} per day',
      padding: EdgeInsets.all(dense ? AppSpacing.sm : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: dense ? 38 : 44,
                height: dense ? 38 : 44,
                decoration: BoxDecoration(
                  color: Color.lerp(scheme.primary, Colors.white, 0.88),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  job.category.icon,
                  size: dense ? 19 : 22,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            job.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: texts.titleMedium,
                          ),
                        ),
                        if (job.isUrgent) ...<Widget>[
                          const SizedBox(width: 6),
                          const StatusChip(
                            label: 'Urgent',
                            color: AppColors.error,
                            icon: Icons.bolt_rounded,
                            dense: true,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.business_rounded,
                          size: 13,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            job.company,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: texts.bodyMedium,
                          ),
                        ),
                        if (verified) ...<Widget>[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            size: 13,
                            color: AppColors.success,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (onSave != null)
                Semantics(
                  button: true,
                  label: isSaved ? 'Remove from saved' : 'Save job',
                  child: IconButton(
                    onPressed: onSave,
                    visualDensity: VisualDensity.compact,
                    tooltip: isSaved ? 'Remove from saved' : 'Save job',
                    icon: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 21,
                      color: isSaved ? scheme.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: dense ? AppSpacing.xs : AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              _MetaPill(
                icon: Icons.calendar_today_rounded,
                label: AppFormat.relativeDay(job.date),
              ),
              _MetaPill(icon: Icons.schedule_rounded, label: job.startTime),
              _MetaPill(
                icon: Icons.near_me_rounded,
                label: AppFormat.distance(job.distanceKm),
              ),
              _MetaPill(
                icon: Icons.group_rounded,
                label: '${job.workersNeeded} needed',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                AppFormat.money(job.pay),
                style: texts.titleMedium?.copyWith(color: scheme.primary),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '/${job.payType.label.toLowerCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: texts.caption,
                ),
              ),
              if (job.travelAllowance > 0 || job.foodAllowance > 0) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    '+ allowances',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: texts.caption?.copyWith(color: AppColors.success),
                  ),
                ),
              ],
              const Spacer(),
              if (showAppliedBadge)
                const StatusChip(
                  label: 'Applied',
                  color: AppColors.info,
                  icon: Icons.send_rounded,
                  dense: true,
                )
              else if (status != null)
                StatusChip.job(status!, dense: true),
            ],
          ),
          if (footer != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12.5, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.caption?.copyWith(fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact variant for horizontal scrollers and dashboard rails.
class JobCardMini extends StatelessWidget {
  const JobCardMini({super.key, required this.job, this.onTap});

  final Job job;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 232,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color.lerp(scheme.primary, Colors.white, 0.88),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    job.category.icon,
                    size: 17,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    job.category.label,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                Text(
                  AppFormat.money(job.pay),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: scheme.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              job.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 2),
            Text(
              '${AppFormat.relativeDay(job.date)} • ${job.startTime}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.caption,
            ),
            Text(
              job.area,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.caption,
            ),
          ],
        ),
      ),
    );
  }
}
