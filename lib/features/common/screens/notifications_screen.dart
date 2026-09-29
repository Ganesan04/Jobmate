import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/enums.dart';
import '../../../models/messaging.dart';
import '../../../navigation/app_router.dart';
import '../../../state/notification_provider.dart';

/// Notification centre grouped by day, with type filters and mark-all-read.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    final NotificationProvider notifications = context
        .read<NotificationProvider>();
    if (notifications.items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => notifications.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final NotificationProvider notifications = context
        .watch<NotificationProvider>();
    final List<AppNotification> items = notifications.visibleItems;

    return AppScaffold(
      appBar: AppTopBar(
        title: 'Notifications',
        actions: <Widget>[
          if (notifications.unreadCount > 0)
            TextButton(
              onPressed: notifications.markAllRead,
              child: const Text('Mark all read'),
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: SelectableChip(
                    label: 'All',
                    selected: notifications.filter == null,
                    onTap: () => notifications.setFilter(null),
                  ),
                ),
                for (final NotificationType type in NotificationType.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: SelectableChip(
                      label: type.label,
                      selected: notifications.filter == type,
                      onTap: () => notifications.setFilter(type),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: notifications.isLoading && notifications.items.isEmpty
                ? const SkeletonList(count: 4)
                : items.isEmpty
                ? EmptyStateView(
                    title: 'You are all caught up',
                    message:
                        'Job updates, payments and messages will appear here.',
                    icon: Icons.notifications_none_rounded,
                  )
                : RefreshIndicator(
                    onRefresh: () => notifications.load(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        AppSpacing.xs,
                        AppSpacing.screen,
                        AppSpacing.xl,
                      ),
                      children: <Widget>[
                        for (final AppNotification item in items)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _NotificationTile(
                              item: item,
                              onTap: () => _open(item),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(AppNotification item) async {
    final NotificationProvider notifications = context
        .read<NotificationProvider>();
    await notifications.markRead(item.id);
    if (!mounted) return;
    final String? route = item.targetRoute;
    if (route == null) return;
    await AppRouter.push(context, route, arguments: item.targetId);
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme texts = Theme.of(context).textTheme;
    final Color tint = _colorFor(item.type);
    return AppCard(
      onTap: onTap,
      color: item.isRead ? AppColors.surface : context.primaryTint,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color.lerp(tint, Colors.white, 0.86),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(item.type.icon, size: 20, color: tint),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: texts.label,
                      ),
                    ),
                    Text(
                      AppFormat.timeAgo(item.createdAt),
                      style: texts.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.body, style: texts.bodyMedium),
              ],
            ),
          ),
          if (!item.isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: AppSpacing.xs, top: 6),
              decoration: BoxDecoration(
                color: context.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  static Color _colorFor(NotificationType type) => type.color;
}
