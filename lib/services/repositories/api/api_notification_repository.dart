import '../../../models/messaging.dart';
import '../../api/api_client.dart';
import '../../api/envelope.dart';
import '../../api/json.dart';
import '../../api/mappers.dart';
import '../notification_repository.dart';
import 'api_query.dart';

/// [NotificationRepository] backed by the notifications endpoints.
class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<AppNotification>> notifications() async {
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/notifications',
      query: pageArgs(),
    );
    return body.dataList(Mappers.notification);
  }

  @override
  Future<int> unreadCount() async => (await unreadCounts()).notifications;

  @override
  Future<({int notifications, int messages})> unreadCounts() async {
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/notifications/unread-count',
    );
    final Map<String, dynamic> data = body.dataMap();
    return (
      notifications: data.integer('notifications'),
      messages: data.integer('messages'),
    );
  }

  @override
  Future<void> markAllRead() => _api.post('/api/v1/notifications/read-all');

  @override
  Future<void> markRead(String id) =>
      _api.post('/api/v1/notifications/$id/read');
}
