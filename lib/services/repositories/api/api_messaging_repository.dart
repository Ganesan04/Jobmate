import '../../../models/messaging.dart';
import '../../api/api_client.dart';
import '../../api/envelope.dart';
import '../../api/json.dart';
import '../../api/mappers.dart';
import '../../api/wire.dart';
import '../messaging_repository.dart';
import 'api_query.dart';

/// [MessagingRepository] backed by the conversations endpoints.
class ApiMessagingRepository implements MessagingRepository {
  ApiMessagingRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Conversation>> conversations() async {
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/conversations',
      query: pageArgs(),
    );
    return body.dataList(Mappers.conversation);
  }

  @override
  Future<List<Message>> messages(String conversationId) async {
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/conversations/$conversationId/messages',
      query: pageArgs(),
    );
    // The feed is returned oldest first, which is the order the chat renders in.
    return body.dataList(Mappers.message);
  }

  @override
  Future<Message> send(String conversationId, String text) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/conversations/$conversationId/messages',
      body: <String, dynamic>{
        'text': text.trim(),
        'messageType': wireMessageTypeText,
      },
    );
    return Mappers.message(body.dataMap());
  }

  @override
  Future<void> markRead(String conversationId) =>
      _api.post('/api/v1/conversations/$conversationId/read');

  @override
  Future<Conversation> startConversation({
    required String participantId,
    required String participantName,
    String jobContext = '',
    String jobId = '',
  }) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/conversations',
      body: jsonBody(<String, dynamic>{
        'participantId': participantId,
        'participantName': participantName.trim(),
        'jobId': jobId.isEmpty ? null : jobId,
        'jobContext': jobContext.trim(),
      }, nulls: <String>{'jobId', 'jobContext'}),
    );
    return Mappers.conversation(body.dataMap());
  }

  @override
  Future<void> archiveConversation(
    String conversationId, {
    bool archived = true,
  }) => _api.post(
    '/api/v1/conversations/$conversationId/archive',
    body: <String, dynamic>{'archived': archived},
  );

  @override
  Future<int> unreadMessageCount() async {
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/notifications/unread-count',
    );
    return body.dataMap().integer('messages');
  }
}
