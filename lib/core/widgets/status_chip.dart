import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// Rounded status pill. Every status colour/icon comes from the enums so the
/// palette stays consistent app-wide.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dense = false,
    this.filled = true,
  });

  /// Builds a chip for an application status.
  factory StatusChip.application(
    ApplicationStatus status, {
    bool dense = false,
  }) {
    return StatusChip(
      label: status.label,
      color: status.color,
      icon: status.icon,
      dense: dense,
    );
  }

  /// Builds a chip for a job status.
  factory StatusChip.job(JobStatus status, {bool dense = false}) {
    return StatusChip(
      label: status.label,
      color: status.color,
      icon: status.icon,
      dense: dense,
    );
  }

  /// Builds a chip for a payment status.
  factory StatusChip.payment(PaymentStatus status, {bool dense = false}) {
    return StatusChip(
      label: status.label,
      color: status.color,
      icon: status.icon,
      dense: dense,
    );
  }

  /// Builds a chip for a verification status.
  factory StatusChip.verification(
    VerificationStatus status, {
    bool dense = false,
  }) {
    return StatusChip(
      label: status.label,
      color: status.color,
      icon: status.icon,
      dense: dense,
    );
  }

  /// Neutral info chip (category, workplace type, etc).
  factory StatusChip.neutral(String label, {IconData? icon, Color? color}) {
    return StatusChip(
      label: label,
      color: color ?? AppColors.textSecondary,
      icon: icon,
    );
  }

  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final Color background = filled
        ? Color.lerp(color, Colors.white, 0.88)!
        : Colors.transparent;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.xs : AppSpacing.sm,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: Color.lerp(color, Colors.white, 0.55)!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 12 : 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Color.lerp(color, Colors.black, 0.18),
              fontWeight: FontWeight.w700,
              fontSize: dense ? 11 : 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable filter chip used across search and create-job flows.
class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.selectedIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final IconData? selectedIcon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 2,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected ? scheme.primary : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(
                    selected ? (selectedIcon ?? icon) : icon,
                    size: 16,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrapping chip list with consistent spacing.
class ChipWrap extends StatelessWidget {
  const ChipWrap({
    super.key,
    required this.children,
    this.spacing = AppSpacing.xs,
    this.runSpacing = AppSpacing.xs,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: spacing, runSpacing: runSpacing, children: children);
  }
}
