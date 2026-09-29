import '../../models/enums.dart';
import '../../models/messaging.dart';

/// In-app notification centre.
///
/// Implemented against `/api/v1/notifications*`.
abstract class NotificationRepository {
  Future<List<AppNotification>> notifications();

  Future<int> unreadCount();

  /// Unread notifications and unread messages, from one call.
  Future<({int notifications, int messages})> unreadCounts();

  Future<void> markAllRead();

  Future<void> markRead(String id);
}

/// Grouping helper used by the notifications screen.
abstract final class NotificationGroups {
  static const List<String> todayLabels = <String>['Today'];

  static String groupLabel(DateTime date, DateTime now) {
    final DateTime a = DateTime(date.year, date.month, date.day);
    final DateTime b = DateTime(now.year, now.month, now.day);
    final int diff = b.difference(a).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'Earlier this week';
    return 'Older';
  }

  static Map<String, List<AppNotification>> group(
    List<AppNotification> items, {
    NotificationType? typeFilter,
    DateTime? now,
  }) {
    final DateTime reference = now ?? DateTime.now();
    final Map<String, List<AppNotification>> result =
        <String, List<AppNotification>>{};
    for (final AppNotification n in items) {
      if (typeFilter != null && n.type != typeFilter) continue;
      final String label = groupLabel(n.createdAt, reference);
      result.putIfAbsent(label, () => <AppNotification>[]).add(n);
    }
    return result;
  }
}
