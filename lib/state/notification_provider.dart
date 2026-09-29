import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/messaging.dart';
import '../services/api/api_exception.dart';
import '../services/repositories/notification_repository.dart';
import 'job_feed_provider.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({required NotificationRepository repository})
    : _repository = repository;

  final NotificationRepository _repository;

  LoadState _state = LoadState.idle;
  String? _error;
  List<AppNotification> _items = <AppNotification>[];
  NotificationType? _filter;

  LoadState get state => _state;
  String? get error => _error;
  bool get isLoading => _state == LoadState.loading;
  bool get hasError => _state == LoadState.error;
  List<AppNotification> get items => _items;
  NotificationType? get filter => _filter;
  int get unreadCount => _items.where((AppNotification n) => !n.isRead).length;
  bool get isEmpty => _state == LoadState.ready && _items.isEmpty;

  List<AppNotification> get visibleItems => _filter == null
      ? _items
      : _items.where((AppNotification n) => n.type == _filter).toList();

  Future<void> load() async {
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      _items = await _repository.notifications();
      _state = LoadState.ready;
    } on ApiException catch (failure) {
      _error = failure.message;
      _state = LoadState.error;
    } catch (_) {
      _error = 'Could not load notifications';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> retry() => load();

  void setFilter(NotificationType? type) {
    _filter = type;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    await _repository.markAllRead();
    _items = await _repository.notifications();
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    await _repository.markRead(id);
    _items = await _repository.notifications();
    notifyListeners();
  }
}
