import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'app_buttons.dart';

/// Shimmer-free skeleton block (placeholder) used while lists load.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.height = 16,
    this.width,
    this.radius = AppRadius.sm,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.border,
              AppColors.surfaceMuted,
              _controller.value,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// Card-shaped skeleton matching [JobCard]'s layout.
class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          Row(
            children: <Widget>[
              SkeletonBox(height: 40, width: 40, radius: AppRadius.md),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SkeletonBox(height: 15, width: 160),
                    SizedBox(height: AppSpacing.xs),
                    SkeletonBox(height: 12, width: 110),
                  ],
                ),
              ),
              SkeletonBox(height: 22, width: 58, radius: AppRadius.pill),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(height: 12, width: double.infinity),
          SizedBox(height: AppSpacing.xs),
          SkeletonBox(height: 12, width: 200),
        ],
      ),
    );
  }
}

/// Vertical skeleton list used by every list screen.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.itemBuilder});

  final int count;
  final Widget? Function(BuildContext context, int index)? itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screen),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (BuildContext context, int index) =>
          itemBuilder?.call(context, index) ?? const JobCardSkeleton(),
    );
  }
}

/// Centred spinner for inline loading (button areas, small sections).
class InlineLoader extends StatelessWidget {
  const InlineLoader({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          if (label != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Helpful empty state: icon, title, message and optional action.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: compact ? AppSpacing.lg : AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: compact ? 60 : 76,
            height: compact ? 60 : 76,
            decoration: BoxDecoration(
              color: Color.lerp(scheme.primary, Colors.white, 0.88),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: compact ? 28 : 34, color: scheme.primary),
          ),
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: compact ? 180 : 220,
              child: PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: true,
                icon: Icons.refresh_rounded,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error state with retry.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'We could not load this right now. Please try again.',
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      title: title,
      message: message,
      icon: Icons.wifi_tethering_error_rounded,
      actionLabel: onRetry == null ? null : retryLabel,
      onAction: onRetry,
    );
  }
}

/// Standard async switch used by every data-driven screen:
/// skeleton -> content / empty / error.
class AsyncStateView extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.isLoading,
    required this.isError,
    required this.isEmpty,
    required this.child,
    this.onRetry,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
  });

  final bool isLoading;
  final bool isError;
  final bool isEmpty;
  final Widget child;
  final VoidCallback? onRetry;
  final Widget? loadingBuilder;
  final Widget? emptyBuilder;
  final Widget? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingBuilder ?? const SkeletonList();
    }
    if (isError) {
      return errorBuilder ?? ErrorStateView(onRetry: onRetry);
    }
    if (isEmpty) {
      return emptyBuilder ??
          const EmptyStateView(
            title: 'Nothing here yet',
            message:
                'New items will show up here as soon as they are available.',
          );
    }
    return child;
  }
}
