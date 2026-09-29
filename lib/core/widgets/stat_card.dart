import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../utils/context_extensions.dart';

/// Dashboard statistic tile: big value, label, icon in a role-tinted circle.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.caption,
    this.onTap,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? caption;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color tint = color ?? scheme.primary;
    final TextTheme texts = Theme.of(context).textTheme;

    return Semantics(
      button: onTap != null,
      label: '$label: $value',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.subtle,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: compact ? 28 : 32,
                      height: compact ? 28 : 32,
                      decoration: BoxDecoration(
                        color: Color.lerp(tint, Colors.white, 0.86),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(icon, size: compact ? 15 : 17, color: tint),
                    ),
                    const Spacer(),
                    if (caption != null)
                      Text(
                        caption!,
                        style: texts.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (compact ? texts.titleMedium : texts.headlineSmall)
                        ?.copyWith(color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: texts.bodyMedium?.copyWith(fontSize: 12.5),
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

/// Row of stat cards that adapts from 4 columns to 2 on narrow phones.
class StatGrid extends StatelessWidget {
  const StatGrid({
    super.key,
    required this.stats,
    this.columns,
    this.spacing = AppSpacing.sm,
  });

  final List<StatCard> stats;
  final int? columns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int count =
            columns ??
            (constraints.maxWidth > 420
                ? 4
                : (constraints.maxWidth > 330 ? 2 : 1));
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: 104,
          ),
          itemBuilder: (BuildContext context, int index) => stats[index],
        );
      },
    );
  }
}

/// Prominent money tile used on Earnings and Payment screens.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.title,
    required this.amount,
    this.subtitle,
    this.icon,
    this.gradient = const <Color>[Color(0xFF0F766E), Color(0xFF14B8A6)],
    this.onTap,
  });

  final String title;
  final String amount;
  final String? subtitle;
  final IconData? icon;
  final List<Color> gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.raised,
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const Spacer(),
                  if (icon != null)
                    Icon(
                      icon,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 30,
                  ),
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.caption?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
