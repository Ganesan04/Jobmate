import 'package:flutter/foundation.dart';

import '../models/messaging.dart';
import '../services/api/api_exception.dart';
import '../services/repositories/messaging_repository.dart';
import 'job_feed_provider.dart';

/// Conversation list + open thread state.
class ChatProvider extends ChangeNotifier {
  ChatProvider({required MessagingRepository repository})
    : _repository = repository;

  final MessagingRepository _repository;

  LoadState _state = LoadState.idle;
  String? _error;
  List<Conversation> _conversations = <Conversation>[];
  final Map<String, List<Message>> _threads = <String, List<Message>>{};
  final Set<String> _sending = <String>{};

  LoadState get state => _state;
  String? get error => _error;
  bool get isLoading => _state == LoadState.loading;
  bool get hasError => _state == LoadState.error;
  List<Conversation> get conversations => _conversations;
  int get unreadTotal =>
      _conversations.fold<int>(0, (int sum, Conversation c) => sum + c.unread);

  Conversation? conversationById(String id) {
    for (final Conversation c in _conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<Message> thread(String conversationId) =>
      _threads[conversationId] ?? <Message>[];

  bool isSending(String conversationId) => _sending.contains(conversationId);

  Future<void> load() async {
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      _conversations = await _repository.conversations();
      _state = LoadState.ready;
    } on ApiException catch (failure) {
      _error = failure.message;
      _state = LoadState.error;
    } catch (_) {
      _error = 'Could not load messages';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> retry() => load();

  Future<void> openThread(String conversationId) async {
    _threads[conversationId] = await _repository.messages(conversationId);
    await _repository.markRead(conversationId);
    _conversations = await _repository.conversations();
    notifyListeners();
  }

  Future<bool> send(String conversationId, String text) async {
    if (text.trim().isEmpty) return false;
    _sending.add(conversationId);
    notifyListeners();
    final Message message = await _repository.send(conversationId, text.trim());
    _threads[conversationId] = <Message>[...(thread(conversationId)), message];
    _conversations = await _repository.conversations();
    _sending.remove(conversationId);
    notifyListeners();
    return true;
  }

  Future<Conversation> startConversation({
    required String participantId,
    required String participantName,
    String jobContext = '',
  }) async {
    final Conversation created = await _repository.startConversation(
      participantId: participantId,
      participantName: participantName,
      jobContext: jobContext,
    );
    _conversations = await _repository.conversations();
    _threads[created.id] = <Message>[];
    notifyListeners();
    return created;
  }
}
