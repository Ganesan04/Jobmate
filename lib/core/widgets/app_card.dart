import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// The app's standard rounded surface (16-24px radius, soft shadow).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.color = AppColors.surface,
    this.borderColor,
    this.radius = AppRadius.xl,
    this.margin,
    this.elevated = true,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Color? borderColor;
  final double radius;
  final EdgeInsetsGeometry? margin;
  final bool elevated;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 1.2),
        boxShadow: elevated ? AppShadows.card : null,
      ),
      child: child,
    );

    if (onTap == null) {
      return Semantics(
        label: semanticLabel,
        container: true,
        child: Padding(padding: margin ?? EdgeInsets.zero, child: content),
      );
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            splashColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.06),
            highlightColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.04),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Slim divider used inside cards instead of the default themed divider.
class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.height = 1, this.indent = 0});

  final double height;
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: EdgeInsets.symmetric(horizontal: indent),
      color: AppColors.border,
    );
  }
}
