import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../utils/context_extensions.dart';

/// Label + value row used on detail screens (payment breakdown, work history...).
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.bold = false,
    this.valueWidget,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final bool bold;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 16, color: context.texts.bodyMedium!.color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(child: Text(label, style: texts.bodyMedium)),
          const SizedBox(width: AppSpacing.sm),
          if (valueWidget != null)
            valueWidget!
          else
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: (bold ? texts.titleMedium : texts.labelLarge)?.copyWith(
                  color: valueColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Card section with a title and a list of rows (used on job details).
class InfoSection extends StatelessWidget {
  const InfoSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 17, color: context.primary),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (trailing case final Widget widget) widget,
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Card(
          child: Padding(
            padding: padding,
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

/// Grouped list row used on Settings / Help / Profile menus.
class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.destructive = false,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool destructive;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: dense ? AppSpacing.xs + 2 : AppSpacing.sm + 2,
          ),
          child: Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      destructive
                          ? AppColors.error
                          : (iconColor ?? context.primary),
                      Colors.white,
                      0.88,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: destructive
                        ? AppColors.error
                        : (iconColor ?? context.primary),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: destructive ? AppColors.error : null,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.caption,
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card that groups a set of [MenuTile]s.
class MenuGroup extends StatelessWidget {
  const MenuGroup({super.key, required this.children, this.title, this.margin});

  final List<Widget> children;
  final String? title;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tiles = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      tiles.add(children[i]);
      if (i != children.length - 1) {
        tiles.add(const Divider(height: 1, indent: 60));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (title != null) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xxs,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              title!.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
        Card(
          margin: margin,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Column(children: tiles),
          ),
        ),
      ],
    );
  }
}
